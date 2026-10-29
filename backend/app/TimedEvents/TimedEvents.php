<?php

namespace App\TimedEvents;

use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * The admin's timed events [Sprint 23]: none is permanent, each runs from starts_at to ends_at as the admin set
 * them, in every league (league_id null) or in one. What each kind does (config game.timed_events.kinds):
 * madness makes the outside buyers and the market's renewal faster (App\Market\Buyer, Pool), progression makes
 * every training step bigger (App\Training\Training), discount makes the pool cheaper (App\Market\Market), and
 * offers, in_form and legends bring special players to each renewal of the market (App\Market\Pool).
 */
class TimedEvents
{
    public const KINDS = ['madness', 'progression', 'discount', 'offers', 'in_form', 'legends'];

    /** Kinds that bring players to the market: their start renews it. */
    public const PLAYERS = ['offers', 'in_form', 'legends'];

    /** The events running now in this league (its own and the ones for every league). */
    public static function active(?int $leagueId): array
    {
        $now = GameClock::now();

        return DB::table('timed_events')->where('starts_at', '<=', $now)->where('ends_at', '>', $now)
            ->where(fn ($q) => $q->whereNull('league_id')->when($leagueId, fn ($q) => $q->orWhere('league_id', $leagueId)))
            ->orderBy('ends_at')->get()->all();
    }

    /** The strongest running event of this kind in this league, or null. */
    public static function running(string $kind, ?int $leagueId): ?object
    {
        return collect(self::active($leagueId))->where('kind', $kind)->sortByDesc('power')->first();
    }

    /** Its power, or $none when no event of this kind runs. */
    public static function power(string $kind, ?int $leagueId, int $none = 0): int
    {
        return ($e = self::running($kind, $leagueId)) ? (int) $e->power : $none;
    }

    /** A multiplier in bp (madness, progression): 10000 when none runs. */
    public static function times(string $kind, ?int $leagueId): int
    {
        return max(10000, self::power($kind, $leagueId, 10000));
    }

    /** For the coach's screens: what runs now and until when, one per kind (the one in effect), of these kinds if given. */
    public static function forScreen(?int $leagueId, ?array $kinds = null): array
    {
        return collect(self::active($leagueId))->when($kinds, fn ($c) => $c->whereIn('kind', $kinds))
            ->groupBy('kind')->map(fn ($g) => $g->sortByDesc('power')->first())->sortBy('ends_at')->values()
            ->map(fn ($e) => ['kind' => $e->kind, 'power' => (int) $e->power, 'ends_at' => Carbon::parse($e->ends_at, 'UTC')->toIso8601ZuluString()])->all();
    }

    /** Every event of these kinds running now, in any league. */
    public static function runningOf(array $kinds): array
    {
        $now = GameClock::now();

        return DB::table('timed_events')->whereIn('kind', $kinds)->where('starts_at', '<=', $now)->where('ends_at', '>', $now)->get()->all();
    }
}
