<?php

namespace App\League;

use App\Models\League;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Random\Engine\Mt19937;
use Random\Randomizer;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * The live draw [X26]. The owner sets a time before the start; a seed is drawn then and only its hash is shown
 * (sha256 of "legends-draw:{league}:{seed}"), so nobody, the owner included, can change the draw after. At the
 * time the seed orders the clubs into the slots of the league calendar and draws the cup, the calendar is made
 * again from them, and the seed is shown: anyone can check it gives the hash and the same order. The members
 * watch it slot by slot on the shared clock.
 */
class LiveDraw
{
    /** The owner sets (or moves) the time while the league waits and nothing is drawn. */
    public static function schedule(League $league, string $at): void
    {
        $when = Carbon::parse($at)->utc();
        if ($league->settings_locked_at || $league->drawn_at) {
            throw new HttpException(409, 'القرعة سُحبت أو بدأ الدوري.');
        }
        if ($when->lte(GameClock::now()) || $when->gt($league->starts_at)) {
            throw new HttpException(422, 'موعد القرعة بعد الآن وقبل بداية الدوري.');
        }
        $seed = $league->draw_seed ?? random_int(1, 2_147_483_647);
        DB::table('leagues')->where('id', $league->id)->whereNull('drawn_at')->update([
            'draw_at' => $when, 'draw_seed' => $seed, 'draw_commit' => self::commit($league->id, $seed), 'updated_at' => GameClock::now(),
        ]);
    }

    /** [Sprint 27] A draw this minute: its seed and hash set, then drawn. */
    public static function now(League $league): bool
    {
        $seed = $league->draw_seed ?? random_int(1, 2_147_483_647);
        DB::table('leagues')->where('id', $league->id)->whereNull('drawn_at')->update([
            'draw_at' => GameClock::now(), 'draw_seed' => $seed, 'draw_commit' => self::commit($league->id, $seed), 'updated_at' => GameClock::now(),
        ]);

        return self::draw($league->fresh());
    }

    public static function commit(int $leagueId, int $seed): string
    {
        return hash('sha256', "legends-draw:{$leagueId}:{$seed}");
    }

    /** The pure draw: the clubs (by id) in their slots, from the seed. */
    public static function order(array $clubIds, int $seed): array
    {
        sort($clubIds);

        return (new Randomizer(new Mt19937($seed)))->shuffleArray($clubIds);
    }

    /** The draws whose time has come (also just before a league starts). Returns how many. */
    public static function due(): int
    {
        $n = 0;
        foreach (DB::table('leagues')->whereNull('drawn_at')->whereNotNull('draw_at')->where('draw_at', '<=', GameClock::now())->pluck('id') as $id) {
            $n += self::draw(League::findOrFail($id)) ? 1 : 0;
        }

        return $n;
    }

    public static function draw(League $league): bool
    {
        return DB::transaction(function () use ($league) {
            $clubs = DB::table('clubs')->where('league_id', $league->id)->pluck('id')->map(fn ($id) => (int) $id)->all();
            $order = self::order($clubs, (int) $league->draw_seed);
            $now = GameClock::now();
            if (DB::table('leagues')->where('id', $league->id)->whereNull('drawn_at')->update(['drawn_at' => $now, 'draw_order' => json_encode($order), 'updated_at' => $now]) !== 1) {
                return false;
            }
            $fresh = $league->fresh();
            SeasonScheduler::build($fresh, $fresh->season);

            return true;
        });
    }

    /** The cup's seed: the drawn one in a league that had its draw, its first season. */
    public static function cupSeed(League $league, object $season): int
    {
        return $league->drawn_at && (int) $season->number === 1 ? (int) $league->draw_seed : crc32('cup:'.$season->id);
    }

    /** The clubs in calendar order: the drawn slots in the first season of a league that had its draw. */
    public static function slots(League $league, object $season, array $byStrength): array
    {
        if (! $league->drawn_at || (int) $season->number !== 1) {
            return $byStrength;
        }
        $drawn = array_values(array_intersect(json_decode($league->draw_order, true) ?? [], $byStrength));

        return [...$drawn, ...array_values(array_diff($byStrength, $drawn))];
    }
}
