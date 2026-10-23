<?php

namespace App\Economy;

use App\League\ClubLedger;
use App\Messages\Inbox;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Club money through the season [PLAN 2.7, 2.9, Sprint 23]. After every match: the home side's sponsors and
 * tickets; and in the league, each side's wages and result bonus, then the debt count (three league rounds
 * in a row below zero sells the dearest player to the pool, again until the club is back above zero). At the
 * end of the league and of the cup, the prizes. Bots earn and pay like everyone. Every movement goes through
 * ClubLedger with a key made from the match, so publishing a match twice never pays twice.
 */
class Economy
{
    public const OFFERS = ['steady', 'bonus', 'ambitious'];

    /** The league's money scale: its clubs' average squad value, kept when first asked (at the start). */
    public static function scale(int $leagueId): int
    {
        $scale = DB::table('leagues')->where('id', $leagueId)->value('money_scale');
        if ($scale) {
            return (int) $scale;
        }
        $clubs = max(1, DB::table('clubs')->where('league_id', $leagueId)->count());
        $scale = intdiv((int) DB::table('players')->where('league_id', $leagueId)->whereNotNull('club_id')->sum('value'), $clubs);
        DB::table('leagues')->where('id', $leagueId)->whereNull('money_scale')->update(['money_scale' => $scale]);

        return $scale;
    }

    public static function squadValue(int $clubId): int
    {
        return (int) DB::table('players')->where('club_id', $clubId)->sum('value');
    }

    /** Everything a finished match moves, once. */
    public static function afterMatch(object $f, array $score): void
    {
        $season = DB::table('seasons')->where('id', $f->season_id)->first();
        $scale = self::scale($season->league_id);
        $money = Money::fromConfig();
        $won = ['home' => $score['home'] > $score['away'], 'away' => $score['away'] > $score['home']];

        // The home side's gate: each sector's sponsor and the tickets.
        foreach (self::contracts($f->home_id, $season->id) as $sector => $offer) {
            ClubLedger::post($f->home_id, 'sponsor', $money->sponsor($scale, $season->rounds, $sector, $offer, $won['home']),
                "sponsor:{$f->id}:{$sector}", "fixture:{$f->id}");
        }
        [$min, $max] = self::strengthRange($season->league_id);
        $strength = (int) DB::table('clubs')->where('id', $f->home_id)->value('strength_snapshot');
        ClubLedger::post($f->home_id, 'tickets', $money->tickets($scale, $season->rounds, $money->attendance($strength, $min, $max)),
            "tickets:{$f->id}", "fixture:{$f->id}");

        if ($f->competition !== 'league') {
            return;
        }
        foreach (['home' => $f->home_id, 'away' => $f->away_id] as $side => $clubId) {
            $other = $side === 'home' ? 'away' : 'home';
            ClubLedger::post($clubId, 'wages', -$money->wages(self::squadValue($clubId), $season->rounds), "wages:{$f->id}:{$clubId}", "fixture:{$f->id}");
            $bonus = $money->resultBonus($scale, $score[$side], $score[$other]);
            if ($bonus > 0) {
                ClubLedger::post($clubId, $score[$side] > $score[$other] ? 'win_bonus' : 'draw_bonus', $bonus, "bonus:{$f->id}:{$clubId}", "fixture:{$f->id}");
            }
            self::debt($clubId, $f->id, $money);
        }
    }

    /**
     * The debt count after a league round [PLAN 2.7]: below zero adds a round (the first one tells the coach),
     * above resets it; at the limit the dearest player goes to the pool for 70% of his value, until the club is
     * above zero again.
     */
    private static function debt(int $clubId, int $fixtureId, Money $money): void
    {
        $club = DB::table('clubs')->where('id', $clubId)->first();
        if ($club->balance >= 0) {
            DB::table('clubs')->where('id', $clubId)->where('debt_rounds', '>', 0)->update(['debt_rounds' => 0]);

            return;
        }
        $rounds = $club->debt_rounds + 1;
        DB::table('clubs')->where('id', $clubId)->update(['debt_rounds' => $rounds]);
        $limit = (int) config('game.economy.debt_rounds_before_forced_sale');
        if ($rounds === 1) {
            Inbox::send($club->user_id, 'in_debt', ['club' => $club->name, 'balance' => (int) $club->balance, 'rounds' => $limit], $club->league_id, $clubId);
        }
        if ($rounds < $limit) {
            return;
        }
        $balance = (int) $club->balance;
        $sold = [];
        while ($balance < 0) {
            $p = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
                ->where('players.club_id', $clubId)->orderByDesc('players.value')->orderBy('players.id')
                ->select('players.id', 'players.base_value', 'master_players.name')->first();
            if (! $p || DB::table('players')->where('club_id', $clubId)->count() <= (int) config('game.economy.min_squad')) {
                break;
            }
            DB::table('players')->where('id', $p->id)->where('club_id', $clubId)->update(['club_id' => null, 'updated_at' => GameClock::now()]);
            $balance = ClubLedger::post($clubId, 'forced_sale', $money->poolPays((int) $p->base_value), "forced:{$fixtureId}:{$p->id}", "player:{$p->id}");
            $sold[] = $p->name;
        }
        DB::table('clubs')->where('id', $clubId)->update(['debt_rounds' => 0]);
        if ($sold) {
            Inbox::send($club->user_id, 'forced_sale', ['club' => $club->name, 'players' => $sold, 'rounds' => $limit], $club->league_id, $clubId);
        }
    }

    /** The league is over: prizes by final place. */
    public static function leaguePrizes(int $seasonId, array $table): void
    {
        $season = DB::table('seasons')->where('id', $seasonId)->first();
        $scale = self::scale($season->league_id);
        $money = Money::fromConfig();
        foreach (array_values($table) as $i => $clubId) {
            $prize = $money->leaguePrize($scale, $i + 1);
            if ($prize > 0) {
                ClubLedger::post($clubId, 'league_prize', $prize, "prize:league:{$seasonId}:{$clubId}", 'place:'.($i + 1));
            }
        }
    }

    /** A cup tie decided: the final pays both sides, a semi-final its loser. */
    public static function cupPrizes(object $tie, int $winner, int $loser): void
    {
        $scale = self::scale((int) DB::table('seasons')->where('id', $tie->season_id)->value('league_id'));
        $money = Money::fromConfig();
        $pay = $tie->stage === 'final' ? [[$winner, 'winner'], [$loser, 'final']] : ($tie->stage === 'sf' ? [[$loser, 'sf']] : []);
        foreach ($pay as [$clubId, $reached]) {
            ClubLedger::post($clubId, 'cup_prize', $money->cupPrize($scale, $reached), "prize:cup:{$tie->season_id}:{$clubId}:{$reached}", "cup:{$reached}");
        }
    }

    /** Each sector's sponsor this season; a sector left unchosen signs the steady one at its first home match. */
    public static function contracts(int $clubId, int $seasonId): array
    {
        $chosen = DB::table('sponsor_contracts')->where('club_id', $clubId)->where('season_id', $seasonId)->pluck('offer', 'sector')->all();
        foreach (array_keys(config('game.economy.sectors')) as $sector) {
            if (! isset($chosen[$sector])) {
                DB::table('sponsor_contracts')->insertOrIgnore(['club_id' => $clubId, 'season_id' => $seasonId, 'sector' => $sector,
                    'offer' => 'steady', 'created_at' => GameClock::now()]);
                $chosen[$sector] = DB::table('sponsor_contracts')->where('club_id', $clubId)->where('season_id', $seasonId)->where('sector', $sector)->value('offer');
            }
        }

        return $chosen;
    }

    /** The coach signs a sector's sponsor for the season: once. */
    public static function sign(int $clubId, int $seasonId, string $sector, string $offer): void
    {
        $new = DB::table('sponsor_contracts')->insertOrIgnore(['club_id' => $clubId, 'season_id' => $seasonId, 'sector' => $sector,
            'offer' => $offer, 'created_at' => GameClock::now()]);
        if ($new !== 1) {
            throw new HttpException(409, 'لهذا القطاع راعٍ هذا الموسم.');
        }
    }

    /** The weakest and strongest club of the league (attendance follows a club's place between them). */
    public static function strengthRange(int $leagueId): array
    {
        $r = DB::table('clubs')->where('league_id', $leagueId)->selectRaw('min(strength_snapshot) as lo, max(strength_snapshot) as hi')->first();

        return [(int) $r->lo, (int) $r->hi];
    }
}
