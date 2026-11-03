<?php

namespace App\League;

use App\Http\Controllers\Api\DataController;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;

/**
 * A league's settings, free or customized [UP9, the owner's spec 4, 2026-10-26].
 *
 * Free: every club of the real league, one round a day at the creator's evening (game.league.default_kickoff in their
 * own time zone), two days to get ready, the integrity system and the press conferences on, no fair league and no
 * second time slot, one season. Changing any of these makes it a customized league, paid once in coins: the number
 * of its clubs × game.league.custom_coins_per_club. A league keeps at least half the real league's clubs.
 */
class LeagueTiers
{
    /** The settings that make a league customized when they differ from the free ones. */
    public const CUSTOM = ['team_count', 'prep_days', 'round_times', 'starting_budget', 'fair_league', 'integrity', 'press_conferences', 'second_slot_minutes', 'season_end_mode'];

    /** How many clubs the real league has (the most a league of it can have, up to the game's max). */
    public static function clubsOf(string $template): int
    {
        $n = DB::table('master_clubs')->where('data_version', DataController::version())->where('league_name', $template)->where('source', '!=', 'nation')->count();

        return min($n, (int) config('game.league.max_teams'));
    }

    /** The fewest clubs: half the real league's (rounded up), never under the game's own minimum. */
    public static function minClubs(int $full): int
    {
        return min($full, max((int) config('game.league.min_teams'), intdiv($full * (int) config('game.league.min_teams_share_bp') + 9999, 10000)));
    }

    /** The free settings for a league of this template, its rounds at the creator's evening in the schedule's zone. */
    public static function free(string $template, ?string $timezone): array
    {
        return [
            'team_count' => self::clubsOf($template),
            'prep_days' => (int) config('game.league.free_prep_days'),
            'rounds_per_day' => 1,
            'round_times' => [self::localKickoff($timezone)],
            'starting_budget' => (int) config('game.economy.starting_budget'),
            'fair_league' => false, 'integrity' => true, 'press_conferences' => true,
            'second_slot_minutes' => null, 'season_end_mode' => 'end',
        ];
    }

    /** The default kickoff in the creator's own zone, as a time in the schedule's zone (Africa/Cairo). */
    public static function localKickoff(?string $timezone): string
    {
        $zone = $timezone && in_array($timezone, \DateTimeZone::listIdentifiers(), true) ? $timezone : 'Africa/Cairo';
        [$h, $m] = array_map('intval', explode(':', (string) config('game.league.default_kickoff')));

        return GameClock::now()->setTimezone($zone)->setTime($h, $m)->setTimezone('Africa/Cairo')->format('H:i');
    }

    /** The settings that differ from the free ones (none: a free league). */
    public static function changed(array $settings, array $free): array
    {
        $norm = fn ($v) => is_array($v) ? array_values($v) : (is_bool($v) ? $v : ($v === null ? null : (string) $v));

        return array_values(array_filter(self::CUSTOM, fn ($k) => array_key_exists($k, $settings) && $norm($settings[$k]) !== $norm($free[$k])));
    }

    /** The coins a customized league of this many clubs costs. */
    public static function cost(int $teamCount): int
    {
        return $teamCount * (int) config('game.league.custom_coins_per_club');
    }
}
