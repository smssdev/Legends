<?php

namespace App\League;

use App\Models\League;
use App\Models\Season;
use App\Support\GameClock;
use App\Tournament\TournamentScheduler;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;

/**
 * A season's calendar [PLAN 2.4, 2.5, 2.10]. First the plan, pure: league rounds packed rounds_per_day to a
 * day, a cup day of its own after some rounds (one match per team, at the day's first time), the final
 * inside the lock zone and before the last league round, and one day with no matches after mid-season
 * (the winter window). Then the calendar puts each day on a date: the preparation days from the start,
 * then the round times in Cairo (they stay at their local hour across a clock change). A development
 * league plays one slot a minute instead [Sprint 15 B4].
 */
class SeasonScheduler
{
    /**
     * @return list<array{type: string, rounds?: list<int>, stage?: int}> days in order: league (its rounds), cup (stage index), rest
     */
    public static function plan(int $teams, int $roundsPerDay): array
    {
        $rounds = LeagueFactory::rounds($teams);
        $winter = intdiv($rounds, 2);
        $breaks = [$winter => ['rest']];
        foreach (self::cupAfter($teams) as $stage => $after) {
            $breaks[$after][] = $stage;
        }
        $days = [];
        $day = [];
        for ($r = 1; $r <= $rounds; $r++) {
            $day[] = $r;
            if (count($day) === $roundsPerDay || isset($breaks[$r]) || $r === $rounds) {
                $days[] = ['type' => 'league', 'rounds' => $day];
                $day = [];
            }
            // The rest day comes first when both fall after the same round: the cup moves to the next gap.
            foreach ($breaks[$r] ?? [] as $b) {
                $days[] = $b === 'rest' ? ['type' => 'rest'] : ['type' => 'cup', 'stage' => $b];
            }
        }

        return $days;
    }

    /**
     * After which league round each cup stage is played (stage index => round). Spread out, the final
     * after round F: inside the lock zone (F ≥ its first round) and before the last round (F < R).
     */
    public static function cupAfter(int $teams): array
    {
        $rounds = LeagueFactory::rounds($teams);
        $lock = LeagueFactory::lockFromRound($rounds);
        $final = max($lock, min($rounds - 1, intdiv($lock + $rounds - 1, 2)));
        $count = count(CupBracket::stages($teams));
        $after = [];
        $prev = 0;
        for ($i = 1; $i <= $count; $i++) {
            $at = $i === $count ? $final : max($prev + 1, intdiv($i * $final, $count));
            $after[$i - 1] = $prev = $at;
        }

        return $after;
    }

    /**
     * The time of every slot: [day index => list of UTC times] (a league day has one per round, a cup day
     * one, a rest day none), and the rest day's date.
     *
     * @return array{slots: array<int, list<CarbonImmutable>>, rest: ?CarbonImmutable}
     */
    public static function calendar(array $days, CarbonImmutable $startsAt, int $prepDays, array $roundTimes, bool $dev = false): array
    {
        $slots = [];
        $rest = null;
        if ($dev) {
            $unit = config('game.clock.dev_round_minutes');
            $at = $startsAt->addMinutes($prepDays * $unit);
            foreach ($days as $i => $d) {
                $n = $d['type'] === 'league' ? count($d['rounds']) : 1;
                $slots[$i] = [];
                for ($k = 0; $k < $n; $k++) {
                    if ($d['type'] === 'rest') {
                        $rest = $at;
                    } else {
                        $slots[$i][] = $at;
                    }
                    $at = $at->addMinutes($unit);
                }
            }

            return ['slots' => $slots, 'rest' => $rest];
        }
        $tz = 'Africa/Cairo';
        $prepEnd = $startsAt->addDays($prepDays);
        $date = $prepEnd->setTimezone($tz)->startOfDay();
        // The first day whose first round is not before the preparation ends.
        if (self::at($date, $roundTimes[0])->lt($prepEnd)) {
            $date = $date->addDay();
        }
        foreach ($days as $i => $d) {
            $slots[$i] = match ($d['type']) {
                'league' => array_map(fn ($k) => self::at($date, $roundTimes[$k]), array_keys($d['rounds'])),
                'cup' => [self::at($date, $roundTimes[0])],
                'rest' => [],
            };
            if ($d['type'] === 'rest') {
                $rest = $date;
            }
            $date = $date->addDay();
        }

        return ['slots' => $slots, 'rest' => $rest];
    }

    /** A Cairo date at a Cairo "HH:MM", in UTC. */
    private static function at(CarbonImmutable $cairoDate, string $time): CarbonImmutable
    {
        [$h, $m] = array_map('intval', explode(':', $time));

        return CarbonImmutable::create($cairoDate->year, $cairoDate->month, $cairoDate->day, $h, $m, 0, 'Africa/Cairo')->utc();
    }

    /** Make (or make again, before the start) the season's fixtures, cup bracket and windows. */
    /** Minutes from the round's time to its second slot, or 0 for a league that plays each round at once [X31]. */
    public static function secondSlot(League $league): int
    {
        if (! $league->second_slot_minutes) {
            return 0;
        }

        return $league->is_dev ? (int) config('game.staggered.dev_minutes') : (int) $league->second_slot_minutes;
    }

    public static function build(League $league, Season $season): void
    {
        // [Sprint 27] A tournament has its own shape.
        if ($league->kind === 'tournament') {
            TournamentScheduler::build($league, $season);

            return;
        }
        DB::transaction(function () use ($league, $season) {
            foreach (['transfer_windows', 'cup_ties', 'fixtures'] as $table) {
                DB::table($table)->where('season_id', $season->id)->delete();
            }
            $clubs = DB::table('clubs')->where('league_id', $league->id)->orderByDesc('strength_snapshot')->orderBy('id')->pluck('id')->all();
            // After a live draw, its slots [X26].
            $clubs = LiveDraw::slots($league, $season, $clubs);
            $days = self::plan(count($clubs), $league->rounds_per_day);
            $cal = self::calendar($days, CarbonImmutable::parse($season->starts_at), $league->prep_days, $league->round_times, $league->is_dev);
            $now = GameClock::now();

            // League: the rounds in order, each at its slot.
            $rounds = RoundRobin::rounds($clubs);
            $leagueTimes = [];
            $cupTimes = [];
            foreach ($days as $i => $d) {
                if ($d['type'] === 'league') {
                    foreach ($d['rounds'] as $k => $r) {
                        $leagueTimes[$r] = $cal['slots'][$i][$k];
                    }
                } elseif ($d['type'] === 'cup') {
                    $cupTimes[$d['stage']] = $cal['slots'][$i][0];
                }
            }
            // A round in two time slots [X31]: half its matches after the league's gap, every match of the round locked
            // together before the first slot, and the slots shared out fairly (Staggered).
            $gap = self::secondSlot($league);
            $strength = DB::table('clubs')->where('league_id', $league->id)->pluck('strength_snapshot', 'id')->map(fn ($v) => (int) $v)->all();
            $slots = $gap ? Staggered::split(array_column($rounds, 'matches'), $strength) : [];
            $lock = (int) config('game.match.lock_minutes_before');
            $rows = [];
            foreach ($rounds as $r => $round) {
                foreach ($round['matches'] as $i => [$home, $away]) {
                    $slot = $slots[$r][$i] ?? 1;
                    $at = $slot === 2 ? $leagueTimes[$r + 1]->addMinutes($gap) : $leagueTimes[$r + 1];
                    $rows[] = ['season_id' => $season->id, 'competition' => 'league', 'round' => $r + 1, 'scheduled_at' => $at,
                        'home_id' => $home, 'away_id' => $away, 'is_bye' => false, 'created_at' => $now, 'updated_at' => $now,
                        'slot' => $slot, 'lock_at' => $gap ? $leagueTimes[$r + 1]->subMinutes($lock) : null];
                }
                if ($round['rest'] !== null) {
                    $rows[] = ['season_id' => $season->id, 'competition' => 'league', 'round' => $r + 1, 'scheduled_at' => $leagueTimes[$r + 1],
                        'home_id' => $round['rest'], 'away_id' => null, 'is_bye' => true, 'created_at' => $now, 'updated_at' => $now,
                        'slot' => 1, 'lock_at' => null];
                }
            }
            foreach (array_chunk($rows, 200) as $chunk) {
                DB::table('fixtures')->insert($chunk);
            }

            // Cup: the drawn bracket, each tie with its fixture on its stage's day (teams filled as they win).
            $stages = CupBracket::stages(count($clubs));
            self::bracket($season->id, CupBracket::draw($clubs, LiveDraw::cupSeed($league, $season)), $stages, $cupTimes);

            // The two windows that renew the market pool [PLAN 2.4]: the preparation, and the winter day.
            $first = min($leagueTimes);
            $last = max(array_merge($leagueTimes, $cupTimes));
            $rest = $cal['rest']?->utc();
            $after = collect($leagueTimes)->filter(fn ($t) => $rest && $t->gt($rest))->min();
            DB::table('transfer_windows')->insert([
                ['season_id' => $season->id, 'kind' => 'summer', 'opens_at' => $season->starts_at, 'closes_at' => $first, 'created_at' => $now, 'updated_at' => $now],
                ['season_id' => $season->id, 'kind' => 'winter', 'opens_at' => $rest, 'closes_at' => $after ?? $last, 'created_at' => $now, 'updated_at' => $now],
            ]);

            $start = CarbonImmutable::parse($season->starts_at);
            $seconds = (int) $start->diffInSeconds($last);
            DB::table('seasons')->where('id', $season->id)->update([
                'ends_at' => $last, 'winter_break_on' => $cal['rest']?->setTimezone('Africa/Cairo')->toDateString(), 'updated_at' => $now,
            ]);
            // Timers (training, stadium) follow the season's length against the reference 37 days [PLAN 2.10].
            DB::table('leagues')->where('id', $league->id)->update([
                'timer_scale' => max(1, intdiv($seconds * 10000, config('game.league.reference_season_days') * 86400)),
            ]);
        });
    }

    /**
     * A knockout's ties with their fixtures, each on its stage's time (sides filled as they win) [PLAN 2.5]; a tie may
     * say where its sides come from (home_from, away_from: a tournament's groups, Sprint 27).
     *
     * @param  list<array{stage: string, slot: int, home: ?int, away: ?int, next: ?array}>  $ties
     * @param  list<string>  $stages  in the order they are played
     * @param  array<int, \DateTimeInterface>  $times  stage index => kick-off
     */
    public static function bracket(int $seasonId, array $ties, array $stages, array $times): void
    {
        $now = GameClock::now();
        $ids = [];
        $next = [];
        foreach ($ties as $tie) {
            $stage = array_search($tie['stage'], $stages, true);
            $fixture = DB::table('fixtures')->insertGetId(['season_id' => $seasonId, 'competition' => 'cup', 'round' => $stage + 1,
                'scheduled_at' => $times[$stage], 'home_id' => $tie['home'], 'away_id' => $tie['away'], 'created_at' => $now, 'updated_at' => $now]);
            $ids[$tie['stage'].':'.$tie['slot']] = DB::table('cup_ties')->insertGetId(['season_id' => $seasonId, 'stage' => $tie['stage'], 'slot' => $tie['slot'],
                'home_id' => $tie['home'], 'away_id' => $tie['away'], 'fixture_id' => $fixture, 'created_at' => $now, 'updated_at' => $now,
                'home_from' => $tie['home_from'] ?? null, 'away_from' => $tie['away_from'] ?? null]);
            $next[$tie['stage'].':'.$tie['slot']] = $tie['next'];
        }
        foreach ($next as $key => $to) {
            if ($to) {
                DB::table('cup_ties')->where('id', $ids[$key])->update(['next_tie_id' => $ids[$to[0].':'.$to[1]], 'next_side' => $to[2]]);
            }
        }
    }
}
