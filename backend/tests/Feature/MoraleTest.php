<?php

namespace Tests\Feature;

use App\League\ClubLedger;
use App\League\MatchRunner;
use App\League\Morale;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X25] Morale: results, the run without a win, the mental coach, the crowd and the tickets. */
class MoraleTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    private object $fixture;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1,
            'starts_at' => GameClock::now()->toIso8601ZuluString()]);
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/start")->assertOk();
        $mine = $this->league['my_club_id'];
        $this->fixture = DB::table('fixtures')->where('competition', 'league')->where('round', 1)->where('is_bye', false)
            ->where(fn ($q) => $q->where('home_id', $mine)->orWhere('away_id', $mine))->first();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function morale(int $clubId): int
    {
        return (int) DB::table('clubs')->where('id', $clubId)->value('morale');
    }

    public function test_results_move_morale_and_a_winless_run_more(): void
    {
        $id = $this->league['my_club_id'];
        $this->assertSame(70, $this->morale($id));
        Morale::after($id, 2, 0);
        $this->assertSame(76, $this->morale($id));
        Morale::after($id, 1, 1);
        $this->assertSame(74, $this->morale($id));
        // The second match without a win costs more.
        Morale::after($id, 0, 1);
        $this->assertSame(66, $this->morale($id));
        $this->assertSame(2, (int) DB::table('clubs')->where('id', $id)->value('winless_run'));
        Morale::after($id, 3, 1);
        $this->assertSame(0, (int) DB::table('clubs')->where('id', $id)->value('winless_run'));

        // Never past the limits.
        DB::table('clubs')->where('id', $id)->update(['morale' => 98]);
        Morale::after($id, 1, 0);
        $this->assertSame(100, $this->morale($id));
        DB::table('clubs')->where('id', $id)->update(['morale' => 22, 'winless_run' => 5]);
        Morale::after($id, 0, 4);
        $this->assertSame(20, $this->morale($id));
    }

    public function test_the_mental_coach_softens_a_bad_result(): void
    {
        $id = $this->league['my_club_id'];
        DB::table('staff_specialists')->insert(['club_id' => $id, 'type' => 'mental_coach', 'stars' => 4, 'cost' => 1, 'idempotency_key' => 'm',
            'starts_at' => GameClock::now()->subHour(), 'ends_at' => GameClock::now()->addDays(3), 'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        Morale::after($id, 0, 1);
        $this->assertSame(68, $this->morale($id));   // -6 + 4
        Morale::after($id, 1, 1);
        $this->assertSame(68, $this->morale($id));   // -2 - 2 + 4, never up after a bad result
        $offers = $this->getJson("/api/v1/leagues/{$this->league['id']}/specialists")->assertOk()->json('specialists');
        $this->assertStringContainsString('المعنويات', collect($offers)->firstWhere('type', 'mental_coach')['offers'][4]['effect']);
    }

    public function test_the_crowd_counts_twice_at_home_and_tickets_cheer_a_side(): void
    {
        $f = $this->fixture;
        $base = fn (string $side) => $this->morale($side === 'home' ? $f->home_id : $f->away_id);
        $this->assertSame($base('home') + 6, Morale::forMatch($f, 'home'));
        $this->assertSame($base('away') + 3, Morale::forMatch($f, 'away'));
        $this->assertSame($base('home') + 3, Morale::forMatch($f, 'home', 'neutral'));

        // A coach of another club in the league buys a ticket for my match? Mine is mine: I buy one for theirs.
        $url = "/api/v1/leagues/{$this->league['id']}/tickets";
        $list = $this->getJson($url)->assertOk()->json();
        $this->assertNotContains($f->id, array_column($list['fixtures'], 'id'));
        $this->assertNotEmpty($list['fixtures']);
        $other = DB::table('fixtures')->where('id', $list['fixtures'][0]['id'])->first();
        $this->assertNotContains($this->league['my_club_id'], [$other->home_id, $other->away_id]);
        $before = (int) DB::table('clubs')->where('id', $this->league['my_club_id'])->value('balance');
        $this->postJson($url, ['fixture_id' => $other->id, 'side' => 'away'])->assertOk();
        $this->assertSame($before - $list['price'], (int) DB::table('clubs')->where('id', $this->league['my_club_id'])->value('balance'));
        $this->assertSame(ClubLedger::sum($this->league['my_club_id']), (int) DB::table('clubs')->where('id', $this->league['my_club_id'])->value('balance'));
        $this->assertSame($this->morale($other->away_id) + 3 + 2, Morale::forMatch($other, 'away'));
        $row = collect($this->getJson($url)->json('fixtures'))->firstWhere('id', $other->id);
        $this->assertSame('away', $row['mine']);
        $this->assertSame(1, $row['cheering']['away']);

        $this->postJson($url, ['fixture_id' => $other->id, 'side' => 'home'])->assertStatus(409);
        $this->postJson($url, ['fixture_id' => $f->id, 'side' => 'home'])->assertStatus(422);
        DB::table('fixtures')->where('season_id', $f->season_id)->update(['status' => 'locked']);
        $third = DB::table('fixtures')->where('season_id', $f->season_id)->where('is_bye', false)->where('id', '!=', $other->id)
            ->where('home_id', '!=', $this->league['my_club_id'])->where('away_id', '!=', $this->league['my_club_id'])->first();
        if ($third) {
            $this->postJson($url, ['fixture_id' => $third->id, 'side' => 'home'])->assertStatus(409);
        }
    }

    public function test_a_played_match_leaves_its_mark_on_both_and_the_team_shows_it(): void
    {
        Carbon::setTestNow(Carbon::parse($this->fixture->scheduled_at, 'UTC')->addMinutes(11));
        MatchRunner::step();
        $f = DB::table('fixtures')->where('id', $this->fixture->id)->first();
        $this->assertSame('finished', $f->status);
        // Every finished match moved both clubs by the rules, in the order they were played.
        $expect = [];
        $run = [];
        $order = DB::table('matches')->join('fixtures', 'fixtures.id', '=', 'matches.fixture_id')->where('fixtures.status', 'finished')
            ->orderBy('matches.id')->get(['fixtures.home_id', 'fixtures.away_id', 'fixtures.home_goals', 'fixtures.away_goals']);
        foreach ($order as $m) {
            foreach ([[$m->home_id, $m->home_goals, $m->away_goals], [$m->away_id, $m->away_goals, $m->home_goals]] as [$id, $for, $against]) {
                $expect[$id] ??= 70;
                $run[$id] ??= 0;
                $run[$id] = $for > $against ? 0 : $run[$id] + 1;
                $change = $for > $against ? 6 : ($for === $against ? -2 : -6) - ($run[$id] >= 2 ? 2 : 0);
                $expect[$id] = max(20, min(100, $expect[$id] + $change));
            }
        }
        foreach ($expect as $id => $value) {
            $this->assertSame($value, $this->morale($id), "club {$id}");
        }
        $state = json_decode(DB::table('matches')->where('fixture_id', $f->id)->value('initial_state'), true);
        $this->assertSame(76, $state['teams']['home']['morale']);
        $this->assertSame(73, $state['teams']['away']['morale']);
        $this->getJson("/api/v1/leagues/{$this->league['id']}/team")->assertJsonPath('morale.value', $this->morale($this->league['my_club_id']));
    }
}
