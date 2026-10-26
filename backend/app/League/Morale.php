<?php

namespace App\League;

use App\Economy\Economy;
use App\Staff\Specialists;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Morale [X25], 0..100 per club. A win lifts it, a draw or a defeat lowers it, and a run of matches without a
 * win lowers it more; the mental coach softens a bad result by his stars. In a match each side adds its crowd:
 * the home side's counts twice on its own ground (the same for both on a neutral one), and every ticket a
 * league coach bought to cheer it adds a little. Like the chemistry, the engine reads only the number: it
 * moves the odds of the phases, never a player's ability.
 */
class Morale
{
    /** After a match: the result for this club, its morale and its run. */
    public static function after(int $clubId, int $for, int $against): void
    {
        $c = config('game.morale');
        $club = DB::table('clubs')->where('id', $clubId)->first(['morale', 'winless_run']);
        if ($for > $against) {
            $change = (int) $c['win'];
            $run = 0;
        } else {
            $run = (int) $club->winless_run + 1;
            $change = (int) ($for === $against ? $c['draw'] : $c['loss']) - ($run >= 2 ? (int) $c['winless_extra'] : 0);
            $change += Specialists::effect($clubId, 'mental_coach', 'mental_coach_boost');
            $change = min(0, $change);
        }
        DB::table('clubs')->where('id', $clubId)->update([
            'morale' => max((int) $c['min'], min((int) $c['max'], (int) $club->morale + $change)),
            'winless_run' => min(255, $run),
        ]);
    }

    /** The morale a side takes into this fixture: its own, its crowd and the tickets cheering it. */
    public static function forMatch(object $fixture, string $side, string $venue = 'home'): int
    {
        $c = config('game.morale');
        $clubId = $side === 'home' ? $fixture->home_id : $fixture->away_id;
        $crowd = (int) $c['crowd'] * ($venue === 'home' && $side === 'home' ? 2 : 1);
        $tickets = min((int) $c['tickets_max'], (int) $c['ticket'] * DB::table('match_tickets')->where('fixture_id', $fixture->id)->where('side', $side)->count());
        // [UP12] The coach's statement at the press conference.
        $press = DB::table('press_statements')->where('fixture_id', $fixture->id)->where('club_id', $clubId)->exists() ? (int) config('game.press.morale') : 0;

        return max(0, min(100, (int) DB::table('clubs')->where('id', $clubId)->value('morale') + $crowd + $tickets + $press));
    }

    /** A league coach's ticket to cheer one side at a match that is not his, until its lock. */
    public static function buyTicket(int $clubId, object $fixture, string $side): int
    {
        if (in_array($clubId, [(int) $fixture->home_id, (int) $fixture->away_id], true)) {
            throw new HttpException(422, 'التذاكر لمباريات الآخرين، وجمهورك معك في مبارياتك.');
        }
        if ($fixture->status !== 'scheduled' || $fixture->is_bye) {
            throw new HttpException(409, 'بيع التذاكر لهذه المباراة انتهى.');
        }
        $league = (int) DB::table('seasons')->where('id', $fixture->season_id)->value('league_id');
        $price = self::ticketPrice($league);

        return DB::transaction(function () use ($clubId, $fixture, $side, $price) {
            $added = DB::table('match_tickets')->insertOrIgnore([
                'fixture_id' => $fixture->id, 'club_id' => $clubId, 'side' => $side, 'price' => $price, 'created_at' => GameClock::now(),
            ]);
            if ($added !== 1) {
                throw new HttpException(409, 'لديك تذكرة لهذه المباراة.');
            }
            ClubLedger::post($clubId, 'match_ticket', -$price, "ticket:{$fixture->id}:{$clubId}", "fixture:{$fixture->id}", true);

            return $price;
        });
    }

    public static function ticketPrice(int $leagueId): int
    {
        return max(1, intdiv(Economy::scale($leagueId) * (int) config('game.morale.ticket_cost_bp'), 10000));
    }
}
