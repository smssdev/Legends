<?php

namespace Tests\Feature;

use App\League\CupBracket;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** Sprint 15's definition of done: the calendar and the cup for every team count from 4 to 20 [PLAN 2.4, 2.5]. */
class SeasonScheduleTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(20);
        $this->defaultTeams = 10;
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function season(array $league): object
    {
        return DB::table('seasons')->where('league_id', $league['id'])->first();
    }

    private function fixtures(object $season, ?string $competition = null): Collection
    {
        return DB::table('fixtures')->where('season_id', $season->id)->when($competition, fn ($q) => $q->where('competition', $competition))->get();
    }

    private function cairoDate(string $utc): string
    {
        return Carbon::parse($utc, 'UTC')->timezone('Africa/Cairo')->toDateString();
    }

    public function test_every_team_count_from_4_to_20(): void
    {
        $owner = User::factory()->create();
        $this->withoutMiddleware(ThrottleRequests::class);
        // [UP17] One round a day; each count from a real league of exactly that many clubs (a free league is all of them).
        foreach (range(4, 20) as $n) {
            DB::table('leagues')->delete();
            $this->template($n, "League {$n}");
            $league = $this->makeLeague($owner, ['template' => "League {$n}", 'team_count' => $n,
                'club_id' => DB::table('master_clubs')->where('league_name', "League {$n}")->orderByDesc('strength_cp')->value('id')]);
            $this->checkSeason($league, $n, 1);
        }
    }

    private function checkSeason(array $league, int $n, int $perDay): void
    {
        $label = "{$n} teams, {$perDay} a day";
        $season = $this->season($league);
        $clubs = DB::table('clubs')->where('league_id', $league['id'])->orderByDesc('strength_snapshot')->orderBy('id')->pluck('id')->all();
        $all = $this->fixtures($season);
        $games = $all->where('competition', 'league')->where('is_bye', false);
        $rounds = $n % 2 === 0 ? 2 * ($n - 1) : 2 * $n;

        // Every team meets every other twice: once at home, once away.
        $pairs = $games->map(fn ($f) => $f->home_id.'-'.$f->away_id);
        $this->assertSame($n * ($n - 1), $pairs->count(), $label);
        $this->assertSame($pairs->count(), $pairs->unique()->count(), $label);
        // Each round: every team once, playing or resting; with an odd count each team rests once in each half.
        foreach (range(1, $rounds) as $r) {
            $inRound = $all->where('competition', 'league')->where('round', $r)->flatMap(fn ($f) => array_filter([$f->home_id, $f->away_id]))->sort()->values()->all();
            $this->assertSame(collect($clubs)->sort()->values()->all(), $inRound, "{$label}, round {$r}");
        }
        $rests = $all->where('is_bye', true);
        $this->assertSame($n % 2 === 1 ? 2 * $n : 0, $rests->count(), $label);
        foreach ($rests->groupBy('home_id') as $club => $byes) {
            $this->assertSame([1, 1], [$byes->where('round', '<=', $rounds / 2)->count(), $byes->where('round', '>', $rounds / 2)->count()], $label);
        }
        // Rounds are played in order.
        $times = $games->groupBy('round')->map(fn ($g) => $g->pluck('scheduled_at')->unique()->all());
        foreach (range(1, $rounds) as $r) {
            $this->assertCount(1, $times[$r], "{$label}: one time per round");
        }
        foreach (range(2, $rounds) as $r) {
            $this->assertGreaterThan($times[$r - 1][0], $times[$r][0], $label);
        }

        // No team plays twice at once, and on a cup day nothing else is played.
        $played = $all->where('is_bye', false)->flatMap(fn ($f) => array_map(fn ($c) => $c.'@'.$f->scheduled_at, array_filter([$f->home_id, $f->away_id])));
        $this->assertSame($played->count(), $played->unique()->count(), $label);
        if ($perDay === 1) {
            $days = $games->flatMap(fn ($f) => [$f->home_id.'@'.$this->cairoDate($f->scheduled_at), $f->away_id.'@'.$this->cairoDate($f->scheduled_at)]);
            $this->assertSame($days->count(), $days->unique()->count(), "{$label}: one match a day");
        }
        $cupDays = $all->where('competition', 'cup')->map(fn ($f) => $this->cairoDate($f->scheduled_at))->unique();
        $leagueDays = $games->map(fn ($f) => $this->cairoDate($f->scheduled_at))->unique();
        $this->assertEmpty($cupDays->intersect($leagueDays)->all(), $label);
        // Each cup stage has its own day.
        $this->assertSame(count(CupBracket::stages($n)), $cupDays->count(), $label);

        // The winter day after mid-season: no match at all.
        $this->assertNotNull($season->winter_break_on, $label);
        $this->assertFalse($all->contains(fn ($f) => $this->cairoDate($f->scheduled_at) === $season->winter_break_on), $label);
        $this->assertGreaterThan($times[intdiv($rounds, 2)][0], $season->winter_break_on.' 23:59:59', $label);

        // The final: inside the lock zone and before the last league round.
        $final = $all->where('competition', 'cup')->sortByDesc('round')->first();
        $this->assertGreaterThan($times[$season->lock_from_round][0], $final->scheduled_at, $label);
        $this->assertLessThan($times[$rounds][0], $final->scheduled_at, $label);
        $this->assertSame($season->ends_at, $times[$rounds][0], $label);

        $this->checkCup($season, $clubs, $label);
    }

    private function checkCup(object $season, array $clubs, string $label): void
    {
        $n = count($clubs);
        $size = CupBracket::mainSize($n);
        $stages = CupBracket::stages($n);
        $ties = DB::table('cup_ties')->where('season_id', $season->id)->get();
        // Ties per stage: (n − S) preliminary, then S/2, S/4, … 1.
        $count = $ties->countBy('stage')->all();
        $this->assertSame($n > $size ? $n - $size : null, $count['preliminary'] ?? null, $label);
        $s = $size;
        foreach ($stages as $stage) {
            if ($stage !== 'preliminary') {
                $this->assertSame(intdiv($s, 2), $count[$stage], "{$label}: {$stage}");
                $s = intdiv($s, 2);
            }
        }
        // The weakest 2(n − S) play the preliminary; the strongest are exempt; every club enters once.
        $prelim = $ties->where('stage', 'preliminary')->flatMap(fn ($t) => [$t->home_id, $t->away_id])->sort()->values()->all();
        $this->assertSame(collect(array_slice($clubs, $n - 2 * ($n - $size)))->sort()->values()->all(), $n > $size ? $prelim : [], $label);
        $first = $ties->where('stage', CupBracket::NAMES[$size])->flatMap(fn ($t) => array_filter([$t->home_id, $t->away_id]))->sort()->values()->all();
        $this->assertSame(collect(array_slice($clubs, 0, $n - 2 * ($n - $size)))->sort()->values()->all(), $first, $label);
        // A tree: every tie but the final sends its winner on to a free side of a later tie; the final sends nowhere.
        $byId = $ties->keyBy('id');
        $sides = [];
        foreach ($ties as $t) {
            if ($t->stage === 'final') {
                $this->assertNull($t->next_tie_id, $label);

                continue;
            }
            $next = $byId[$t->next_tie_id];
            $this->assertGreaterThan(array_search($t->stage, $stages), array_search($next->stage, $stages), $label);
            $this->assertNull($t->next_side === 'home' ? $next->home_id : $next->away_id, $label);
            $sides[] = $next->id.$t->next_side;
        }
        $this->assertSame(count($sides), count(array_unique($sides)), $label);
        // Each tie has its fixture on its stage's day.
        $this->assertSame($ties->count(), DB::table('fixtures')->where('season_id', $season->id)->where('competition', 'cup')->count(), $label);
        $this->assertSame(0, $ties->whereNull('fixture_id')->count(), $label);
    }

    public function test_rounds_keep_their_cairo_hour_across_the_clock_change(): void
    {
        // Egypt's summer time ends on the night of 29 to 30 October 2026: 21:00 is 18:00 UTC before, 19:00 after.
        $league = $this->makeLeague(User::factory()->create(), ['team_count' => 10, 'rounds_per_day' => 1, 'round_times' => ['21:00'],
            'starts_at' => '2026-10-23T18:00:00Z']);
        $games = $this->fixtures($this->season($league), 'league')->where('is_bye', false);
        $local = $games->map(fn ($f) => Carbon::parse($f->scheduled_at, 'UTC')->timezone('Africa/Cairo')->format('H:i'))->unique()->values()->all();
        $this->assertSame(['21:00'], $local);
        $utc = $games->map(fn ($f) => substr($f->scheduled_at, 11, 5))->unique()->sort()->values()->all();
        $this->assertSame(['18:00', '19:00'], $utc);
        // The first round comes two days after the start (two preparation days), at its hour.
        $this->assertSame('2026-10-25 18:00:00', $games->min('scheduled_at'));
    }

    public function test_a_development_league_plays_a_round_every_minute(): void
    {
        $league = $this->makeLeague(User::factory()->create(), ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1]);
        $season = $this->season($league);
        $slots = $this->fixtures($season)->pluck('scheduled_at')->unique()->sort()->values();
        // 6 league rounds and 2 cup days, one a minute after one minute of preparation, and one empty minute in winter.
        $this->assertCount(8, $slots);
        $start = Carbon::parse($season->starts_at, 'UTC');
        $this->assertSame($start->copy()->addMinute()->toDateTimeString(), $slots->first());
        $this->assertSame($start->copy()->addMinutes(9)->toDateTimeString(), $slots->last());
        $this->assertLessThanOrEqual(10, (int) DB::table('leagues')->value('timer_scale'));
    }

    public function test_the_timers_scale_with_the_season_length(): void
    {
        // 16 teams, one round a day: 30 rounds, 4 cup days, a rest day and 2 days of preparation, about 37 days.
        $league = $this->makeLeague(User::factory()->create(), ['team_count' => 16, 'rounds_per_day' => 1, 'round_times' => ['21:00'], 'prep_days' => 2]);
        $scale = (int) DB::table('leagues')->where('id', $league['id'])->value('timer_scale');
        $this->assertGreaterThanOrEqual(9500, $scale);
        $this->assertLessThanOrEqual(10300, $scale);
        // Fewer teams, a shorter season: the timers run shorter too.
        $short = $this->makeLeague(User::factory()->create(), ['team_count' => 10]);
        $this->assertLessThan($scale, (int) DB::table('leagues')->where('id', $short['id'])->value('timer_scale'));
    }

    public function test_new_times_before_the_start_remake_the_calendar(): void
    {
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['rounds_per_day' => 1, 'round_times' => ['21:00']]);
        $season = $this->season($league);
        $count = $this->fixtures($season)->count();
        $this->actingAs($owner)->patchJson("/api/v1/leagues/{$league['id']}", ['round_times' => ['17:00']])->assertOk();
        $hours = $this->fixtures($season, 'league')->map(fn ($f) => Carbon::parse($f->scheduled_at, 'UTC')->timezone('Africa/Cairo')->format('H:i'))->unique()->sort()->values()->all();
        $this->assertSame(['17:00'], $hours);
        $this->assertSame($count, $this->fixtures($season)->count());
        // "Start now" moves the whole calendar with it.
        $this->postJson("/api/v1/leagues/{$league['id']}/start")->assertOk();
        $first = Carbon::parse($this->fixtures($season, 'league')->min('scheduled_at'), 'UTC');
        $this->assertTrue($first->lt(GameClock::now()->addDays(3)));
    }

    public function test_the_calendar_table_and_cup_through_the_api(): void
    {
        $owner = User::factory()->create();
        // Five teams: half of a ten-club league [UP9].
        $this->template(10, 'Small League');
        $league = $this->makeLeague($owner, ['template' => 'Small League', 'team_count' => 5,
            'club_id' => DB::table('master_clubs')->where('league_name', 'Small League')->orderByDesc('strength_cp')->value('id')]);
        $url = "/api/v1/leagues/{$league['id']}";
        $this->actingAs(User::factory()->create())->getJson("{$url}/fixtures")->assertNotFound();

        $this->actingAs($owner);
        $fixtures = $this->getJson("{$url}/fixtures")->assertOk()->assertJsonPath('season.rounds', 10)->assertJsonCount(2, 'season.windows')
            // [Sprint 59 F1] Every field Fixture requires in openapi.yaml (the app reads the calendar through it).
            ->assertJsonStructure(['fixtures' => ['*' => ['id', 'competition', 'round', 'scheduled_at', 'is_bye', 'status']]])->json('fixtures');
        // 10 rounds of 2 matches and a rest, then 3 cup stages (1 preliminary, 2 semi-finals, the final).
        $this->assertCount(30 + 4, $fixtures);
        $this->assertStringEndsWith('Z', $fixtures[0]['scheduled_at']);
        $this->assertSame(['preliminary', 'sf', 'final'], collect($fixtures)->where('competition', 'cup')->pluck('stage')->unique()->values()->all());

        // A result in round 1: the table counts it; the club resting in round 2 is marked.
        $first = DB::table('fixtures')->where('competition', 'league')->where('round', 1)->where('is_bye', false)->orderBy('id')->first();
        DB::table('fixtures')->where('competition', 'league')->where('round', 1)->update(['status' => 'finished', 'home_goals' => 1, 'away_goals' => 1]);
        DB::table('fixtures')->where('id', $first->id)->update(['home_goals' => 3, 'away_goals' => 0]);
        $table = $this->getJson("{$url}/standings")->assertOk()->assertJsonPath('next_round', 2)->json('table');
        $this->assertSame([$first->home_id, 3, 1, 3, 3], [$table[0]['id'], $table[0]['points'], $table[0]['played'], $table[0]['goal_difference'], $table[0]['goals_for']]);
        $this->assertSame(4, collect($table)->sum('played'));
        $resting = DB::table('fixtures')->where('round', 2)->where('is_bye', true)->value('home_id');
        $this->assertSame([$resting], collect($table)->where('rests_next', true)->pluck('id')->all());

        $cup = $this->getJson("{$url}/cup")->assertOk()->json('stages');
        $this->assertSame(['preliminary', 'sf', 'final'], array_column($cup, 'stage'));
        $this->assertSame([1, 2, 1], array_map(fn ($s) => count($s['ties']), $cup));
        $this->assertSame([['slot' => 1, 'side' => 'home'], ['slot' => 1, 'side' => 'away']], array_column($cup[1]['ties'], 'next'));
    }
}
