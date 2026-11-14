<?php

namespace App\League;

use App\Engine\AutoPick;
use App\Engine\MatchSetup;
use App\Messages\Inbox;
use App\Models\Club;
use App\Models\LeagueMembership;
use App\Notify\Push;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Before a match [PLAN 2.13]. Thirty minutes before: the referee and his strictness, drawn on the server
 * and kept. Five minutes before, the lock: any injured or suspended starter is replaced by the best
 * substitute (the bench first, then the rest of the squad), then each side's lineup, takers and tactics
 * are frozen for the match. From then until the match ends the sheet cannot be edited.
 */
class MatchPrep
{
    /** Every minute. Returns [referees drawn, fixtures locked]. */
    public static function run(): array
    {
        $now = GameClock::now();
        $refs = 0;
        $lock = (int) config('game.match.lock_minutes_before');
        $before = (int) config('game.match.referee_minutes_before');
        // The referee comes the same time before the lock as ever; a round in two slots locks all at once [X31].
        $due = DB::table('fixtures')->where('status', 'scheduled')->where('is_bye', false)->whereNull('referee_strictness')
            ->whereNotNull('home_id')->whereNotNull('away_id')
            ->where(fn ($q) => $q->where(fn ($q) => $q->whereNull('lock_at')->where('scheduled_at', '<=', $now->copy()->addMinutes($before)))
                ->orWhere(fn ($q) => $q->whereNotNull('lock_at')->where('lock_at', '<=', $now->copy()->addMinutes($before - $lock))))->pluck('id');
        foreach ($due as $id) {
            $strictness = Tactics::REFEREES[random_int(0, 4)];
            $drawn = DB::table('fixtures')->where('id', $id)->whereNull('referee_strictness')
                ->update(['referee_strictness' => $strictness, 'referee_at' => $now, 'updated_at' => $now]);
            $refs += $drawn;
            if ($drawn) {
                self::tellCoaches($id, $strictness);
            }
        }
        self::soon($now);
        self::lineupSoon($now);
        self::remind($now);
        $locks = 0;
        $due = DB::table('fixtures')->where('status', 'scheduled')->where('is_bye', false)->whereNotNull('home_id')->whereNotNull('away_id')
            ->where(fn ($q) => $q->where(fn ($q) => $q->whereNull('lock_at')->where('scheduled_at', '<=', $now->copy()->addMinutes($lock)))
                ->orWhere(fn ($q) => $q->whereNotNull('lock_at')->where('lock_at', '<=', $now)))->orderBy('scheduled_at')->get(['id', 'season_id', 'round', 'competition']);
        foreach ($due as $f) {
            $locks += self::lock($f->id) ? 1 : 0;
        }
        foreach ($due->where('competition', 'league')->unique(fn ($f) => $f->season_id.':'.$f->round) as $f) {
            self::matchOfDay($f->season_id, $f->round);
        }

        return [$refs, $locks];
    }

    /** These players are in no sheet locked for a match not yet over (the match plays with them) [X31]. */
    public static function assertFree(array $playerIds): void
    {
        if (! $playerIds) {
            return;
        }
        $sheets = DB::table('fixture_sheets')->join('fixtures', 'fixtures.id', '=', 'fixture_sheets.fixture_id')
            ->whereIn('fixtures.status', ['locked', 'live'])
            ->whereIn('fixture_sheets.club_id', DB::table('players')->whereIn('id', $playerIds)->whereNotNull('club_id')->pluck('club_id'))
            ->get(['fixture_sheets.starters', 'fixture_sheets.bench']);
        foreach ($sheets as $sheet) {
            if (array_intersect($playerIds, array_map('intval', array_filter([...json_decode($sheet->starters, true), ...json_decode($sheet->bench, true)])))) {
                throw new HttpException(409, 'اللاعب في تشكيلة مقفلة لمباراة لم تنته: انتظر نهايتها.');
            }
        }
    }

    /** When a fixture locks: its own lock_at (a round in two slots, X31), or the usual minutes before its kick-off. */
    public static function lockAt(object $f): Carbon
    {
        return $f->lock_at ? Carbon::parse($f->lock_at, 'UTC') : Carbon::parse($f->scheduled_at, 'UTC')->subMinutes((int) config('game.match.lock_minutes_before'));
    }

    /**
     * In a league with two slots [X31]: a reminder to each coach before the round locks, with his slot, once per
     * fixture ("your club plays in the first slot; the plans lock in two hours").
     */
    private static function remind($now): void
    {
        $ahead = (int) config('game.staggered.remind_minutes');
        $due = DB::table('fixtures')->where('status', 'scheduled')->where('is_bye', false)->whereNull('reminded_at')->whereNotNull('lock_at')
            ->whereNotNull('home_id')->whereNotNull('away_id')->where('lock_at', '>', $now)->where('lock_at', '<=', $now->copy()->addMinutes($ahead))->get();
        foreach ($due as $f) {
            if (DB::table('fixtures')->where('id', $f->id)->whereNull('reminded_at')->update(['reminded_at' => $now]) !== 1) {
                continue;
            }
            $names = DB::table('clubs')->whereIn('id', [$f->home_id, $f->away_id])->pluck('name', 'id');
            $left = max(1, intdiv(Carbon::parse($f->lock_at, 'UTC')->getTimestamp() - $now->getTimestamp() + 59, 60));
            foreach ([[$f->home_id, $f->away_id], [$f->away_id, $f->home_id]] as [$club, $other]) {
                if ($coach = Inbox::coachOf($club)) {
                    // [UP2] In the coach's own language.
                    $en = self::english($coach);
                    $slot = (int) $f->slot === 2 ? ($en ? 'the second slot (evening)' : 'الفترة الثانية (السهرة)') : ($en ? 'the first slot' : 'الفترة الأولى');
                    Push::send($coach, 'match_slot', $en ? "Reminder: your club plays in {$slot}" : "تذكير: ناديك يلعب في {$slot}",
                        $en ? 'Against '.($names[$other] ?? '').". The round's plans all lock in {$left} minutes: check your plan now!"
                            : 'ضد '.($names[$other] ?? '').". تُقفل خطط الجولة كلها بعد {$left} دقيقة: تفقد خطتك الآن!", '/match', (int) DB::table('clubs')->where('id', $club)->value('league_id'));
                }
            }
        }
    }

    /**
     * The night's big match [X31]: once a round in two slots has locked, its most telling second-slot match (the two
     * clubs highest in the table) is named, and every coach of the league is told.
     */
    private static function matchOfDay(int $seasonId, int $round): void
    {
        $night = DB::table('fixtures')->where('season_id', $seasonId)->where('competition', 'league')->where('round', $round)->where('slot', 2)
            ->where('is_bye', false)->get();
        if ($night->isEmpty() || $night->contains(fn ($f) => $f->match_of_day)) {
            return;
        }
        $place = array_flip(Standings::order($seasonId));
        $top = $night->sortBy(fn ($f) => [($place[$f->home_id] ?? 99) + ($place[$f->away_id] ?? 99), $f->id])->first();
        if (DB::table('fixtures')->where('id', $top->id)->where('match_of_day', false)->update(['match_of_day' => true]) !== 1) {
            return;
        }
        $league = DB::table('seasons')->join('leagues', 'leagues.id', '=', 'seasons.league_id')->where('seasons.id', $seasonId)->first(['leagues.id', 'leagues.name']);
        $names = DB::table('clubs')->whereIn('id', [$top->home_id, $top->away_id])->pluck('name', 'id');
        foreach (DB::table('clubs')->where('league_id', $league->id)->whereNotNull('user_id')->pluck('user_id') as $coach) {
            Inbox::send($coach, 'match_of_day', ['league' => $league->name, 'home' => $names[$top->home_id] ?? '', 'away' => $names[$top->away_id] ?? ''], $league->id);
        }
    }

    /** "Your match is in 30 minutes" (game.notifications.match_soon_minutes), once per fixture, to both coaches' devices [PLAN 2.13, Sprint 36]. */
    private static function soon($now): void
    {
        $due = DB::table('fixtures')->whereIn('status', ['scheduled', 'locked'])->where('is_bye', false)->whereNull('soon_at')
            ->whereNotNull('home_id')->whereNotNull('away_id')->where('scheduled_at', '>', $now)
            ->where('scheduled_at', '<=', $now->copy()->addMinutes(config('game.notifications.match_soon_minutes')))->get();
        foreach ($due as $f) {
            if (DB::table('fixtures')->where('id', $f->id)->whereNull('soon_at')->update(['soon_at' => $now]) !== 1) {
                continue;
            }
            $names = DB::table('clubs')->whereIn('id', [$f->home_id, $f->away_id])->pluck('name', 'id');
            foreach ([[$f->home_id, $f->away_id], [$f->away_id, $f->home_id]] as [$club, $other]) {
                if ($coach = Inbox::coachOf($club)) {
                    $minutes = config('game.notifications.match_soon_minutes');
                    Push::send($coach, 'match_soon', self::english($coach) ? "Your match in {$minutes} minutes" : "مباراتك بعد {$minutes} ".($minutes > 10 ? 'دقيقة' : 'دقائق'),
                        self::english($coach) ? 'Against '.($names[$other] ?? '').'. Get in to follow it and manage your team.'
                            : 'ضد '.($names[$other] ?? '').'. ادخل لتتابعها وتدير فريقك.', '/match', (int) DB::table('clubs')->where('id', $club)->value('league_id'));
                }
            }
        }
    }

    /**
     * [Sprint 64 B5] "Is your lineup ready?" (game.notifications.lineup_soon_minutes) before kick-off, once per fixture,
     * to both coaches' devices; the tap opens the lineup. A round in two slots has its own reminder before its lock [X31].
     */
    private static function lineupSoon($now): void
    {
        $minutes = (int) config('game.notifications.lineup_soon_minutes');
        $due = DB::table('fixtures')->where('status', 'scheduled')->where('is_bye', false)->whereNull('lineup_reminded_at')->whereNull('lock_at')
            ->whereNotNull('home_id')->whereNotNull('away_id')->where('scheduled_at', '>', $now->copy()->addMinutes((int) config('game.notifications.match_soon_minutes')))
            ->where('scheduled_at', '<=', $now->copy()->addMinutes($minutes))->get();
        foreach ($due as $f) {
            if (DB::table('fixtures')->where('id', $f->id)->whereNull('lineup_reminded_at')->update(['lineup_reminded_at' => $now]) !== 1) {
                continue;
            }
            $names = DB::table('clubs')->whereIn('id', [$f->home_id, $f->away_id])->pluck('name', 'id');
            foreach ([[$f->home_id, $f->away_id], [$f->away_id, $f->home_id]] as [$club, $other]) {
                if ($coach = Inbox::coachOf($club)) {
                    $en = self::english($coach);
                    $who = $names[$other] ?? '';
                    Push::send($coach, 'lineup_soon', $en ? 'Is your lineup ready?' : 'تشكيلتك جاهزة؟',
                        $en ? "Your match against {$who} kicks off in an hour: check your lineup and plan."
                            : "مباراتك ضد {$who} بعد ساعة: تفقد تشكيلتك وخطتك.", '/lineup', (int) DB::table('clubs')->where('id', $club)->value('league_id'));
                }
            }
        }
    }

    /** The referee goes to both coaches' inboxes [PLAN 2.13, Sprint 22 B2]. */
    private static function tellCoaches(int $fixtureId, string $strictness): void
    {
        $f = DB::table('fixtures')->join('seasons', 'seasons.id', '=', 'fixtures.season_id')->join('leagues', 'leagues.id', '=', 'seasons.league_id')
            ->where('fixtures.id', $fixtureId)->select('fixtures.*', 'leagues.id as league_id', 'leagues.name as league')->first();
        $names = DB::table('clubs')->whereIn('id', [$f->home_id, $f->away_id])->pluck('name', 'id');
        foreach ([[$f->home_id, $f->away_id], [$f->away_id, $f->home_id]] as [$club, $other]) {
            Inbox::send(Inbox::coachOf($club), 'referee', ['league' => $f->league, 'opponent' => $names[$other] ?? '',
                'strictness' => $strictness, 'fixture_id' => $f->id, 'at' => $f->scheduled_at], $f->league_id, $club);
        }
    }

    /** Lock one fixture: fix and freeze both sides. False when another run got there first. */
    public static function lock(int $fixtureId): bool
    {
        return DB::transaction(function () use ($fixtureId) {
            $now = GameClock::now();
            $fixture = DB::table('fixtures')->where('id', $fixtureId)->first();
            $changed = DB::table('fixtures')->where('id', $fixtureId)->where('status', 'scheduled')
                ->update(['status' => 'locked', 'locked_at' => $now, 'updated_at' => $now,
                    // A match locked without its 30-minute call (the server was off) still gets a referee.
                    'referee_strictness' => $fixture->referee_strictness ?? Tactics::REFEREES[random_int(0, 4)]]);
            if ($changed !== 1) {
                return false;
            }
            foreach ([$fixture->home_id, $fixture->away_id] as $clubId) {
                $club = Club::find($clubId);
                // A bot picks its eleven afresh, resting the tired, and its tactics for this opponent [Sprint 32].
                // [UP13] A coach who was not there: his assistant picks, resting the tired, with balanced tactics.
                $assistant = ! $club->isBot() && self::absent($club, $fixture);
                [$lineup, $fixes] = $club->isBot() ? [TeamSheet::best($club, Bot::restBelow($club)), []]
                    : ($assistant ? [TeamSheet::best($club, (int) config('game.assistant.min_fitness'), config('game.assistant.formations')), []] : self::fixed($club));
                DB::table('fixture_sheets')->insert([
                    'fixture_id' => $fixtureId, 'club_id' => $clubId, 'formation' => $lineup['formation'],
                    'slots' => json_encode($lineup['slots']), 'starters' => json_encode($lineup['starters']), 'bench' => json_encode($lineup['bench']),
                    'takers' => json_encode(TeamSheet::sheetTakers($club, $lineup)),
                    'tactics' => json_encode($club->isBot() ? Bot::tacticsFor($club, $fixture) : ($assistant ? MatchSetup::DEFAULT_TACTICS : Tactics::of($club))),
                    'fixes' => json_encode($fixes), 'locked_at' => $now,
                    // The coach's pre-match scenarios [X23], frozen like the rest.
                    'scenarios' => $club->isBot() ? null : json_encode(Scenarios::of($club)),
                    // The squad as it is now: training or the market until kick-off changes nothing in this match [X31].
                    'squad' => json_encode(LeagueMatch::squadRows($clubId)),
                ]);
                if ($assistant) {
                    $other = DB::table('clubs')->where('id', $clubId === $fixture->home_id ? $fixture->away_id : $fixture->home_id)->value('name');
                    Inbox::send($club->user_id, 'assistant_led', ['opponent' => $other, 'league_id' => $club->league_id], $club->league_id, $club->id);
                }
            }

            return true;
        });
    }

    /**
     * [UP13] The coach has not been in his league since his club's last match (so not to set this one's team), or is
     * on holiday: the assistant leads his team in it.
     */
    public static function absent(Club $club, object $fixture): bool
    {
        $m = LeagueMembership::where('league_id', $club->league_id)->where('user_id', $club->user_id)->whereNull('left_at')->with('user')->first();
        if (! $m) {
            return false;
        }
        $kickoff = Carbon::parse($fixture->scheduled_at, 'UTC');
        if (Presence::onHoliday($m, $kickoff) || $m->user?->onVacation($kickoff)) {
            return true;
        }
        // Not seen in the league since his club's last match: he never came to set the team for this one.
        $previous = DB::table('fixtures')->where('id', '!=', $fixture->id)->where('scheduled_at', '<', $fixture->scheduled_at)->where('is_bye', false)
            ->where(fn ($q) => $q->where('home_id', $club->id)->orWhere('away_id', $club->id))->max('scheduled_at');
        $seen = $m->last_active_at ?? $m->joined_at;

        return $previous !== null && ($seen === null || $seen->lt(Carbon::parse($previous, 'UTC')));
    }

    /**
     * The lineup with every injured, suspended or missing starter replaced by the best fit: from the bench
     * first, then the rest of the squad [PLAN 2.13].
     *
     * @return array{0: array, 1: list<array{slot: int, out: ?int, in: int}>}
     */
    public static function fixed(Club $club): array
    {
        $lineup = TeamSheet::current($club);
        $squad = collect(TeamSheet::squad($club))->keyBy('id');
        $fixes = [];
        foreach ($lineup['starters'] as $i => $id) {
            if ($id !== null && $squad->has($id) && ! $squad[$id]['unavailable']) {
                continue;
            }
            $used = array_flip(array_filter($lineup['starters']));
            $slot = $lineup['slots'][$i];
            $fit = ['line' => $slot['line'], 'fits' => TeamSheet::fits($slot['role'])];
            // His own line first [X5]: another line's player only when none is left.
            $score = fn ($p) => $p['a']['ovr'] * 100 - AutoPick::misfit($p, $fit) - (in_array($slot['line'], TeamSheet::linesOf($p), true) ? 0 : TeamSheet::OFF_LINE);
            $pick = null;
            foreach ([$lineup['bench'], $squad->keys()->all()] as $pool) {
                foreach ($pool as $cand) {
                    $p = $squad[$cand] ?? null;
                    if (! $p || $p['unavailable'] || isset($used[$cand]) || ($pick && $score($p) <= $score($squad[$pick]))) {
                        continue;
                    }
                    $pick = $cand;
                }
                if ($pick) {
                    break;
                }
            }
            if ($pick) {
                $lineup['starters'][$i] = $pick;
                $lineup['bench'] = array_values(array_diff($lineup['bench'], [$pick]));
                $fixes[] = ['slot' => $i, 'out' => $id, 'in' => $pick];
            }
        }
        // Whoever is unavailable leaves the bench too.
        $lineup['bench'] = array_values(array_filter($lineup['bench'], fn ($id) => ! $squad[$id]['unavailable']));

        return [$lineup, $fixes];
    }

    /** The club's sheet is frozen from the lock until its match ends. */
    public static function assertOpen(Club $club): void
    {
        $locked = DB::table('fixtures')->whereIn('status', ['locked', 'live'])
            ->where(fn ($q) => $q->where('home_id', $club->id)->orWhere('away_id', $club->id))->exists();
        if ($locked) {
            throw new HttpException(409, 'التشكيلة والتكتيك مقفلان قبل المباراة بخمس دقائق وحتى نهايتها.');
        }
    }

    /** [UP2] Whether a coach plays in English. */
    private static function english(int $userId): bool
    {
        return DB::table('users')->where('id', $userId)->value('locale') === 'en';
    }
}
