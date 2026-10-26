<?php

namespace Tests\Feature;

use App\League\LeagueMatch;
use App\League\MatchPrep;
use App\League\RoundRobin;
use App\League\Staggered;
use App\Market\Market;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X31] A round in two time slots: fair rotation, one lock, the last round together, the night's big match, a frozen squad. */
class StaggeredTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_every_club_plays_as_many_matches_in_each_slot_or_one_apart(): void
    {
        foreach (range(4, 20) as $n) {
            $clubs = range(1, $n);
            $rounds = array_column(RoundRobin::rounds($clubs), 'matches');
            $slots = Staggered::split($rounds, array_combine($clubs, array_map(fn ($c) => 1000 - $c, $clubs)));
            $diff = array_fill_keys($clubs, 0);
            foreach ($rounds as $r => $matches) {
                $second = count(array_filter($slots[$r], fn ($s) => $s === 2));
                if ($r === count($rounds) - 1) {
                    $this->assertSame(0, $second, "{$n} teams: the last round is played all at once");

                    continue;
                }
                // Half the round each side, the odd match to each slot in turn.
                $this->assertContains($second, [intdiv(count($matches), 2), intdiv(count($matches) + 1, 2)], "{$n} teams, round {$r}");
                foreach ($matches as $i => [$h, $a]) {
                    $diff[$h] += $slots[$r][$i] === 1 ? 1 : -1;
                    $diff[$a] += $slots[$r][$i] === 1 ? 1 : -1;
                }
            }
            $this->assertLessThanOrEqual(1, max(array_map('abs', $diff)), "{$n} teams");
        }
        // With the balance even (the first round), the strongest pairing is the night's.
        $first = Staggered::split([[[1, 2], [3, 4]], [[1, 3], [2, 4]]], [1 => 10, 2 => 9, 3 => 1, 4 => 2])[0];
        $this->assertSame([2, 1], $first);
    }

    private function league(array $over = []): array
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();

        return [$owner, $this->makeLeague($owner, $over + ['team_count' => 6, 'rounds_per_day' => 1, 'round_times' => ['16:30'], 'second_slot_minutes' => 240])];
    }

    public function test_the_calendar_splits_each_round_but_the_last_and_locks_it_once(): void
    {
        [, $league] = $this->league();
        $this->assertSame(240, $league['second_slot_minutes']);
        $season = DB::table('seasons')->where('league_id', $league['id'])->value('id');
        $fixtures = DB::table('fixtures')->where('season_id', $season)->where('competition', 'league')->where('is_bye', false)->get();
        $last = $fixtures->max('round');
        foreach ($fixtures->groupBy('round') as $round => $matches) {
            $first = $matches->where('slot', 1)->first();
            $at = Carbon::parse($first->scheduled_at, 'UTC');
            foreach ($matches as $f) {
                $this->assertSame($at->copy()->subMinutes(5)->toDateTimeString(), Carbon::parse($f->lock_at)->toDateTimeString(), "round {$round}: one lock");
                $this->assertSame($f->slot === 2 ? $at->copy()->addMinutes(240)->toDateTimeString() : $at->toDateTimeString(), Carbon::parse($f->scheduled_at)->toDateTimeString());
            }
            $this->assertSame($round === $last ? 0 : [1, 2][$round % 2 === 1 ? 0 : 1], $matches->where('slot', 2)->count(), "round {$round}");
        }
        // The fixtures and the next match say the slot.
        $this->getJson("/api/v1/leagues/{$league['id']}/fixtures")->assertOk()->assertJsonStructure(['fixtures' => [['slot', 'match_of_day']]]);
    }

    public function test_the_second_slot_must_not_run_into_the_next_round(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();
        // [UP17] One round a day: past the most minutes the second slot is refused; within them it fits before tomorrow's round.
        $this->actingAs($owner)->postJson('/api/v1/leagues', $this->settings(['second_slot_minutes' => (int) config('game.staggered.max_minutes') + 1]))
            ->assertStatus(422)->assertJsonValidationErrors('second_slot_minutes');
        $this->makeLeague($owner, ['second_slot_minutes' => 240]);
    }

    public function test_one_lock_for_the_round_then_the_big_match_and_a_frozen_squad(): void
    {
        [$owner, $league] = $this->league();
        $season = DB::table('seasons')->where('league_id', $league['id'])->value('id');
        $round = DB::table('fixtures')->where('season_id', $season)->where('competition', 'league')->where('round', 1)->where('is_bye', false)->get();
        $lockAt = Carbon::parse($round->first()->lock_at, 'UTC');

        // Two hours before the lock: the reminder, once.
        Carbon::setTestNow($lockAt->copy()->subMinutes(100));
        MatchPrep::run();
        $this->assertSame($round->count(), DB::table('fixtures')->whereIn('id', $round->pluck('id'))->whereNotNull('reminded_at')->count());

        // The lock: both slots at once, and the night's big match named for everyone.
        Carbon::setTestNow($lockAt);
        MatchPrep::run();
        $this->assertSame($round->count(), DB::table('fixtures')->whereIn('id', $round->pluck('id'))->where('status', 'locked')->count());
        $big = DB::table('fixtures')->whereIn('id', $round->pluck('id'))->where('match_of_day', true)->get();
        $this->assertCount(1, $big);
        $this->assertSame(2, (int) $big->first()->slot);
        $this->assertTrue(DB::table('messages')->where('user_id', $owner->id)->where('type', 'match_of_day')->exists());

        // After the lock the squad is frozen: training in the four hours changes nothing in the evening match.
        $night = DB::table('fixtures')->whereIn('id', $round->pluck('id'))->where('slot', 2)->first();
        $starter = json_decode(DB::table('fixture_sheets')->where('fixture_id', $night->id)->value('starters'), true)[5];
        $before = (int) DB::table('players')->where('id', $starter)->value('overall');
        DB::table('players')->where('id', $starter)->update(['training_bonus' => 9, 'fitness' => 40]);
        $state = LeagueMatch::state($night, 7);
        $p = collect([...$state['teams']['home']['players'], ...$state['teams']['away']['players']])->firstWhere('id', $starter);
        $this->assertSame($before, $p['a']['ovr']);
        $this->assertNotSame(4000, $p['fit']);

        // And nobody in a locked sheet leaves before his match.
        $club = DB::table('players')->where('id', $starter)->value('club_id');
        $this->expectExceptionMessage('تشكيلة مقفلة');
        Market::sell((int) $club, $starter, 'k1');
    }
}
