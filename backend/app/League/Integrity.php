<?php

namespace App\League;

use App\Economy\Economy;
use App\Staff\Specialists;
use App\Support\GameClock;
use App\Wallet\Price;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Random\Engine\Mt19937;
use Random\Randomizer;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * The integrity system [X28], only where the league's owner switched it on before the start.
 *  - A bribe to the next match's referee: club money and coins (club money in a fair league), until the lock.
 *    At kick-off the VAR catches it one time in five (from the match's seed): lost, and the side's morale
 *    falls; otherwise the referee leans its way (fewer cards for it, more for its opponent, a penalty more often).
 *  - The spy's report says whether the opponent had bribed. A club with a lawyer of enough stars, or one that
 *    paid for a security check, sees the spies on it, and can pay to turn one into a double agent: his report
 *    becomes a fake board.
 *  - With a spy's proof, the wronged club takes it to the FA: a sure verdict confiscates part of the guilty
 *    club's money, bans it from the market for a day, takes points off it, and makes a scandal: a breaking
 *    headline in the league, its morale down and its next home crowd cut.
 */
class Integrity
{
    public static function on(int $leagueId): bool
    {
        return (bool) DB::table('leagues')->where('id', $leagueId)->value('integrity');
    }

    public static function assertOn(int $leagueId): void
    {
        if (! self::on($leagueId)) {
            throw new HttpException(409, 'منظومة النزاهة غير مفعّلة في هذا الدوري.');
        }
    }

    public static function bribeMoney(int $leagueId): int
    {
        return intdiv(Economy::scale($leagueId) * (int) config('game.integrity.bribe_cost_bp'), 10000);
    }

    /** The next fixture of the club that is still open (before its lock). */
    private static function open(int $clubId, int $fixtureId): object
    {
        $f = DB::table('fixtures')->where('id', $fixtureId)->where(fn ($q) => $q->where('home_id', $clubId)->orWhere('away_id', $clubId))->first();
        if (! $f || $f->status !== 'scheduled' || $f->is_bye) {
            throw new HttpException(409, 'هذا ممكن قبل قفل المباراة فقط.');
        }

        return $f;
    }

    public static function bribe(int $clubId, int $fixtureId): void
    {
        $club = DB::table('clubs')->where('id', $clubId)->first();
        self::assertOn($club->league_id);
        $f = self::open($clubId, $fixtureId);
        $money = self::bribeMoney($club->league_id);
        DB::transaction(function () use ($clubId, $f, $money) {
            if (DB::table('bribes')->insertOrIgnore(['fixture_id' => $f->id, 'club_id' => $clubId, 'money' => $money, 'created_at' => GameClock::now()]) !== 1) {
                throw new HttpException(409, 'دفعت للحكم في هذه المباراة.');
            }
            ClubLedger::post($clubId, 'bribe', -$money, "bribe:{$f->id}:{$clubId}", "fixture:{$f->id}", true);
            Price::charge($clubId, 'bribe', $money, "bribe-coins:{$f->id}:{$clubId}", "fixture:{$f->id}");
        });
    }

    /**
     * At kick-off: each bribe of the fixture is caught by the VAR or goes through, from the match's seed. Returns
     * the sides the referee leans to, and lowers the morale of a side caught.
     *
     * @return array{home: bool, away: bool}
     */
    public static function kickOff(object $fixture, int $seed): array
    {
        $out = ['home' => false, 'away' => false];
        foreach (DB::table('bribes')->where('fixture_id', $fixture->id)->whereNull('outcome')->get() as $b) {
            $side = (int) $b->club_id === (int) $fixture->home_id ? 'home' : 'away';
            $caught = crc32("var:{$seed}:{$b->id}") % 10000 < (int) config('game.integrity.var_bp');
            DB::table('bribes')->where('id', $b->id)->update(['outcome' => $caught ? 'var' : 'clean']);
            if ($caught) {
                self::moraleDown($b->club_id, (int) config('game.integrity.var_morale'));
            } else {
                $out[$side] = true;
            }
        }

        return $out;
    }

    private static function moraleDown(int $clubId, int $points): void
    {
        DB::table('clubs')->where('id', $clubId)->update(['morale' => DB::raw('max('.(int) config('game.morale.min').', morale - '.$points.')')]);
    }

    /** Whether this club sees the spies on it for this fixture: a lawyer of enough stars, or a security check paid. */
    public static function seesSpies(int $clubId, int $fixtureId): bool
    {
        return Specialists::stars($clubId, 'lawyer') >= (int) config('game.integrity.lawyer_stars')
            || DB::table('integrity_actions')->where('fixture_id', $fixtureId)->where('club_id', $clubId)->where('kind', 'security')->exists();
    }

    public static function securityCheck(int $clubId, int $fixtureId): void
    {
        $club = DB::table('clubs')->where('id', $clubId)->first();
        self::assertOn($club->league_id);
        $f = self::open($clubId, $fixtureId);
        if (self::seesSpies($clubId, $f->id)) {
            throw new HttpException(409, 'أنت ترى الجواسيس على هذه المباراة بالفعل.');
        }
        DB::transaction(function () use ($clubId, $f, $club) {
            DB::table('integrity_actions')->insert(['fixture_id' => $f->id, 'club_id' => $clubId, 'kind' => 'security', 'created_at' => GameClock::now()]);
            Price::charge($clubId, 'security_check', self::featureMoney($club->league_id, 'security_check'), "security:{$f->id}:{$clubId}", "fixture:{$f->id}");
        });
    }

    /** The spies sent on this club for this fixture (only for a club that sees them). */
    public static function spiesOn(int $clubId, int $fixtureId): array
    {
        $turned = DB::table('integrity_actions')->where('fixture_id', $fixtureId)->where('club_id', $clubId)->where('kind', 'double')->pluck('spy_report_id')->all();

        return DB::table('spy_reports')->join('clubs', 'clubs.id', '=', 'spy_reports.club_id')->where('spy_reports.fixture_id', $fixtureId)
            ->where('spy_reports.target_club_id', $clubId)->get(['spy_reports.id', 'clubs.name'])
            ->map(fn ($s) => ['id' => $s->id, 'club' => $s->name, 'turned' => in_array($s->id, $turned)])->all();
    }

    /** Turn a spy into a double agent: his report becomes a fake board (and says no bribe). */
    public static function turn(int $clubId, int $spyReportId): void
    {
        $club = DB::table('clubs')->where('id', $clubId)->first();
        self::assertOn($club->league_id);
        $spy = DB::table('spy_reports')->where('id', $spyReportId)->where('target_club_id', $clubId)->first();
        if (! $spy) {
            throw new HttpException(404, 'لا جاسوس بهذا الرقم عليك.');
        }
        $f = self::open($clubId, $spy->fixture_id);
        if (! self::seesSpies($clubId, $f->id)) {
            throw new HttpException(403, 'لا ترى الجواسيس: تحتاج محامياً رفيع المستوى أو فحصاً أمنياً.');
        }
        DB::transaction(function () use ($clubId, $spy, $f, $club) {
            if (DB::table('integrity_actions')->where('spy_report_id', $spy->id)->where('kind', 'double')->exists()) {
                throw new HttpException(409, 'هذا الجاسوس صار مزدوجاً بالفعل.');
            }
            DB::table('integrity_actions')->insert(['fixture_id' => $f->id, 'club_id' => $clubId, 'kind' => 'double', 'spy_report_id' => $spy->id, 'created_at' => GameClock::now()]);
            Price::charge($clubId, 'double_agent', self::featureMoney($club->league_id, 'double_agent'), "double:{$spy->id}", "fixture:{$f->id}");
            DB::table('spy_reports')->where('id', $spy->id)->update(['report' => json_encode(self::fake(json_decode($spy->report, true), $spy->id)), 'updated_at' => GameClock::now()]);
        });
    }

    /** A believable board that is not the real one: another formation and other public tactics, and no bribe. */
    public static function fake(array $report, int $seed): array
    {
        $rng = new Randomizer(new Mt19937($seed));
        $names = array_values(array_diff(FormationBook::names(), [$report['formation'] ?? '']));
        $plans = array_values(array_diff(Tactics::RULES['plan'], [$report['tactics']['plan'] ?? '']));
        $report['formation'] = $names[$rng->getInt(0, count($names) - 1)];
        $report['tactics'] = ['plan' => $plans[$rng->getInt(0, count($plans) - 1)], 'tackling' => $rng->getInt(0, 3),
            'marking' => $rng->getInt(0, 1) ? 'man' : 'zone', 'trap' => $rng->getInt(0, 1)];
        // Two starters and two on the bench change places.
        if (count($report['starters'] ?? []) > 2 && count($report['bench'] ?? []) > 2) {
            foreach ([1, 2] as $i) {
                [$report['starters'][$i], $report['bench'][$i]] = [$report['bench'][$i], $report['starters'][$i]];
            }
        }
        $report['bribed'] = false;

        return $report;
    }

    /** With the spy's proof, the wronged club takes the bribe to the FA. The verdict is sure. */
    public static function accuse(int $clubId, int $spyReportId): array
    {
        $spy = DB::table('spy_reports')->where('id', $spyReportId)->where('club_id', $clubId)->first();
        if (! $spy) {
            throw new HttpException(404, 'لا تقرير جاسوس لك بهذا الرقم.');
        }
        $club = DB::table('clubs')->where('id', $clubId)->first();
        self::assertOn($club->league_id);
        $bribe = DB::table('bribes')->where('fixture_id', $spy->fixture_id)->where('club_id', $spy->target_club_id)->first();
        if (! (json_decode($spy->report, true)['bribed'] ?? false) || ! $bribe) {
            throw new HttpException(422, 'لا دليل على رشوة في تقرير جاسوسك.');
        }
        $c = config('game.integrity');

        return DB::transaction(function () use ($clubId, $spy, $bribe, $c) {
            $guilty = DB::table('clubs')->where('id', $spy->target_club_id)->first();
            $season = (int) DB::table('fixtures')->where('id', $spy->fixture_id)->value('season_id');
            $fine = intdiv(max(0, (int) $guilty->balance) * (int) $c['fine_bp'], 10000);
            $added = DB::table('fa_cases')->insertOrIgnore(['season_id' => $season, 'bribe_id' => $bribe->id, 'accuser_club_id' => $clubId,
                'accused_club_id' => $guilty->id, 'fine' => $fine, 'points' => (int) $c['points'], 'created_at' => GameClock::now()]);
            if ($added !== 1) {
                throw new HttpException(409, 'فصلت لجنة الانضباط في هذه القضية.');
            }
            if ($fine > 0) {
                ClubLedger::post($guilty->id, 'fa_fine', -$fine, "fa:{$bribe->id}", "bribe:{$bribe->id}");
            }
            DB::table('clubs')->where('id', $guilty->id)->update([
                'market_banned_until' => GameClock::now()->addHours((int) $c['market_ban_hours']),
                'attendance_cut_bp' => (int) $c['scandal_attendance_bp'],
            ]);
            self::moraleDown($guilty->id, (int) $c['scandal_morale']);

            return ['club' => $guilty->name, 'fine' => $fine, 'points' => (int) $c['points'], 'ban_hours' => (int) $c['market_ban_hours']];
        });
    }

    /** Points taken off a club this season by the FA. */
    public static function deductions(int $seasonId): array
    {
        return DB::table('fa_cases')->where('season_id', $seasonId)->groupBy('accused_club_id')
            ->selectRaw('accused_club_id, sum(points) as pts')->pluck('pts', 'accused_club_id')->map(fn ($p) => (int) $p)->all();
    }

    /** The league's breaking headlines: the verdicts of the last day. */
    public static function headlines(int $leagueId): array
    {
        return DB::table('fa_cases')->join('clubs', 'clubs.id', '=', 'fa_cases.accused_club_id')->where('clubs.league_id', $leagueId)
            ->where('fa_cases.created_at', '>=', GameClock::now()->subHours((int) config('game.integrity.headline_hours')))
            ->orderByDesc('fa_cases.id')->get(['clubs.name', 'fa_cases.points', 'fa_cases.created_at'])
            ->map(fn ($r) => ['text' => sprintf('فضيحة الموسم: إدانة رسمية لنادي %s بتهمة التلاعب والرشوة، وتوقيع عقوبات مشددة!', $r->name), 'points' => (int) $r->points])->all();
    }

    /** Out of the market while banned. */
    public static function assertMarket(int $clubId): void
    {
        $until = DB::table('clubs')->where('id', $clubId)->value('market_banned_until');
        if ($until && GameClock::now()->lt($until)) {
            throw new HttpException(409, 'ناديك محظور من سوق الانتقالات بقرار لجنة الانضباط حتى '.Carbon::parse($until, 'UTC')->setTimezone('Africa/Cairo')->format('H:i').'.');
        }
    }

    private static function featureMoney(int $leagueId, string $feature): int
    {
        return intdiv(Economy::scale($leagueId) * (int) config("game.integrity.{$feature}_cost_bp"), 10000);
    }
}
