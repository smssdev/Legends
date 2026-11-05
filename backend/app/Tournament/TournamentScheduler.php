<?php

namespace App\Tournament;

use App\League\SeasonScheduler;
use App\Models\League;
use App\Models\Season;
use App\Support\GameClock;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 29] A tournament's calendar: its rounds (the league's, or the groups' with every group's round on the same
 * day) packed rounds_per_day to a day, then one day for each knockout stage, at the round times in Cairo (one slot a
 * minute in a development tournament), as a league's season (SeasonScheduler::calendar). Made at creation from a
 * provisional seed, and again from the drawn one.
 */
class TournamentScheduler
{
    /** The seed the tournament is shaped by: the drawn one, or a provisional one until the draw. */
    public static function seed(League $league): int
    {
        return $league->drawn_at ? (int) $league->draw_seed : crc32('tournament:'.$league->id);
    }

    public static function plan(League $league): array
    {
        $teams = DB::table('clubs')->where('league_id', $league->id)->orderByDesc('strength_snapshot')->orderBy('id')->pluck('id')
            ->map(fn ($id) => (int) $id)->all();

        return TournamentPlan::make($teams, self::seed($league), $league->format, (int) ($league->group_count ?: 1),
            (int) ($league->advance_per_group ?: 2), (int) ($league->legs ?: 1), (int) ($league->best_thirds ?: 0));
    }

    /** How many league (or group) rounds a tournament of this shape plays. */
    public static function rounds(int $teams, string $format, int $groupCount, int $legs): int
    {
        if ($format === 'knockout') {
            return 0;
        }
        $size = $format === 'groups' ? intdiv($teams + $groupCount - 1, $groupCount) : $teams;
        $perLeg = $size % 2 === 0 ? $size - 1 : $size;

        return $size < 2 ? 0 : $perLeg * $legs;
    }

    public static function build(League $league, Season $season): void
    {
        DB::transaction(function () use ($league, $season) {
            foreach (['transfer_windows', 'cup_ties', 'fixtures'] as $table) {
                DB::table($table)->where('season_id', $season->id)->delete();
            }
            $plan = self::plan($league);
            DB::table('clubs')->where('league_id', $league->id)->update(['group_no' => null]);
            foreach ($plan['groups'] as $club => $group) {
                DB::table('clubs')->where('id', $club)->update(['group_no' => $group]);
            }
            $stages = TournamentPlan::stages($plan['ties']);
            $days = [];
            $day = [];
            $count = count($plan['rounds']);
            for ($r = 1; $r <= $count; $r++) {
                $day[] = $r;
                if (count($day) === $league->rounds_per_day || $r === $count) {
                    $days[] = ['type' => 'league', 'rounds' => $day];
                    $day = [];
                }
            }
            foreach ($stages as $i => $stage) {
                $days[] = ['type' => 'cup', 'stage' => $i];
            }
            $cal = SeasonScheduler::calendar($days, CarbonImmutable::parse($season->starts_at), $league->prep_days, $league->round_times, $league->is_dev);
            $leagueTimes = $cupTimes = [];
            foreach ($days as $i => $d) {
                if ($d['type'] === 'league') {
                    foreach ($d['rounds'] as $k => $r) {
                        $leagueTimes[$r] = $cal['slots'][$i][$k];
                    }
                } else {
                    $cupTimes[$d['stage']] = $cal['slots'][$i][0];
                }
            }

            $now = GameClock::now();
            $rows = [];
            foreach ($plan['rounds'] as $r => $round) {
                $at = $leagueTimes[$r + 1];
                foreach ($round['matches'] as [$home, $away]) {
                    $rows[] = ['season_id' => $season->id, 'competition' => 'league', 'round' => $r + 1, 'scheduled_at' => $at,
                        'home_id' => $home, 'away_id' => $away, 'is_bye' => false, 'created_at' => $now, 'updated_at' => $now, 'slot' => 1, 'lock_at' => null];
                }
                foreach ($round['rests'] as $rest) {
                    $rows[] = ['season_id' => $season->id, 'competition' => 'league', 'round' => $r + 1, 'scheduled_at' => $at,
                        'home_id' => $rest, 'away_id' => null, 'is_bye' => true, 'created_at' => $now, 'updated_at' => $now, 'slot' => 1, 'lock_at' => null];
                }
            }
            foreach (array_chunk($rows, 200) as $chunk) {
                DB::table('fixtures')->insert($chunk);
            }
            if ($plan['ties']) {
                SeasonScheduler::bracket($season->id, $plan['ties'], $stages, $cupTimes);
            }

            // The market stays shut in a tournament (Market::closed); one window keeps the season's shape.
            $times = array_merge($leagueTimes, $cupTimes);
            $first = min($times);
            $last = max($times);
            DB::table('transfer_windows')->insert(['season_id' => $season->id, 'kind' => 'summer', 'opens_at' => $season->starts_at, 'closes_at' => $first,
                'created_at' => $now, 'updated_at' => $now]);
            $seconds = (int) CarbonImmutable::parse($season->starts_at)->diffInSeconds($last);
            DB::table('seasons')->where('id', $season->id)->update(['ends_at' => $last, 'rounds' => count($plan['rounds']), 'updated_at' => $now]);
            DB::table('leagues')->where('id', $league->id)->update([
                'timer_scale' => max(1, intdiv($seconds * 10000, config('game.league.reference_season_days') * 86400)),
            ]);
        });
    }
}
