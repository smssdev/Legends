<?php

namespace Tests\Feature;

use App\Engine\Ability;
use App\Engine\MatchEngine;
use App\Engine\SeededRandom;
use App\League\ClubLedger;
use App\League\LeagueMatch;
use App\Models\User;
use App\Stadium\Stadium;
use App\Staff\Specialists;
use App\Support\GameClock;
use App\Training\Training;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** The stadium [PLAN 2.9, Sprint 29]: one part at a time, done with the coach away, and every stage's effect. */
class StadiumTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    private int $mine;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'rounds_per_day' => 1, 'round_times' => ['21:00']]);
        $this->mine = $this->league['my_club_id'];
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function url(): string
    {
        return "/api/v1/leagues/{$this->league['id']}/stadium";
    }

    private function start(string $section, string $key = 'k1')
    {
        return $this->actingAs($this->owner)->postJson($this->url(), ['section' => $section, 'idempotency_key' => $key]);
    }

    private function stage(string $section, int $stage): void
    {
        DB::table('stadium_sections')->upsert([['club_id' => $this->mine, 'section' => $section, 'stage' => $stage, 'parts' => 0]], ['club_id', 'section'], ['stage', 'parts']);
    }

    public function test_a_part_is_paid_once_and_only_one_is_built_at_a_time(): void
    {
        $before = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        $cost = Stadium::partCost($this->league['id'], 1);
        $this->assertGreaterThan(0, $cost);
        $this->start('seats')->assertOk()->assertJsonPath('building.section', 'seats')->assertJsonPath('building.part', 1);
        $this->start('seats')->assertOk();
        $this->assertSame($before - $cost, (int) DB::table('clubs')->where('id', $this->mine)->value('balance'));
        $this->start('pitch', 'k2')->assertConflict()->assertJsonPath('message', 'يُبنى جزء الآن، انتظر حتى يكتمل.');

        DB::table('stadium_builds')->update(['status' => 'done']);
        $this->stage('training', 3);
        $this->start('training', 'k3')->assertConflict()->assertJsonPath('message', 'هذا القسم مكتمل.');
        ClubLedger::post($this->mine, 'wages', -100_000_000, 'debt');
        $this->start('pitch', 'k4')->assertConflict()->assertJsonPath('message', 'رصيد النادي لا يكفي.');
    }

    public function test_the_timer_finishes_with_the_coach_away_in_20_hours_and_five_parts_make_a_stage(): void
    {
        // [Sprint 43 C4] A part's time from the league's length: the 45 parts back to back from the season's start end by
        // the round finish_before_rounds before the last (a quarter of the rounds in a short league).
        $seconds = Stadium::partSeconds($this->league['id']);
        $season = DB::table('seasons')->where('league_id', $this->league['id'])->first();
        $rounds = (int) DB::table('fixtures')->where('season_id', $season->id)->where('competition', 'league')->max('round');
        $target = $rounds - min((int) config('game.stadium.finish_before_rounds'), intdiv($rounds, 4));
        $deadline = Carbon::parse(DB::table('fixtures')->where('season_id', $season->id)->where('competition', 'league')->where('round', $target)->min('scheduled_at'), 'UTC');
        $this->assertLessThanOrEqual($deadline->getTimestamp(), Carbon::parse($season->starts_at, 'UTC')->getTimestamp() + 45 * $seconds);
        $this->assertGreaterThan($deadline->getTimestamp() - 45 * 60, Carbon::parse($season->starts_at, 'UTC')->getTimestamp() + 45 * $seconds);
        $this->assertNotSame(20 * 3600, $seconds);
        foreach (range(1, 5) as $part) {
            $this->start('pitch', "p{$part}")->assertOk()->assertJsonPath('building.part', $part);
            Carbon::setTestNow(GameClock::now()->addSeconds($seconds - 60));
            $this->artisan('stadium:due')->assertSuccessful();
            $this->assertNotNull(Stadium::building($this->mine));
            Carbon::setTestNow(GameClock::now()->addSeconds(60));
            $this->artisan('stadium:due')->assertSuccessful();
            $this->assertNull(Stadium::building($this->mine));
            $this->assertSame($part === 5 ? 1 : 0, Stadium::stage($this->mine, 'pitch'));
        }
        $this->assertSame(5, DB::table('messages')->where('user_id', $this->owner->id)->where('type', 'stadium_part')->count());
        $this->assertSame('اكتملت مرحلة في الملعب', $this->getJson('/api/v1/messages')->json('messages.0.title'));
        $this->getJson($this->url())->assertJsonPath('sections.1.stage', 1)->assertJsonPath('sections.1.next.stage', 2)
            ->assertJsonPath('facts.parts_done', 5)->assertJsonPath('facts.home_bp', (int) config('game.match.home_base_bp') + 200);
    }

    public function test_seats_bring_more_seats_and_more_from_each_home_match(): void
    {
        $finance = fn () => $this->actingAs($this->owner)->getJson("/api/v1/leagues/{$this->league['id']}/team/finance")->json('stadium');
        $was = $finance();
        $this->assertSame(20000, $was['capacity']);
        foreach ([1 => 25000, 2 => 31000, 3 => 38000] as $stage => $capacity) {
            $this->stage('seats', $stage);
            $now = $finance();
            $this->assertSame($capacity, $now['capacity']);
            $this->assertGreaterThan($was['tickets_per_match'], $now['tickets_per_match']);
            $was = $now;
        }
    }

    public function test_the_pitch_adds_to_the_home_advantage_in_the_match(): void
    {
        $f = DB::table('fixtures')->where('competition', 'league')->where('home_id', $this->mine)->orderBy('scheduled_at')->first();
        Carbon::setTestNow(Carbon::parse($f->scheduled_at, 'UTC')->subMinutes(5));
        $this->artisan('matches:prepare')->assertSuccessful();
        $ability = function (array $state): int {
            $engine = (new \ReflectionClass(MatchEngine::class))->newInstanceWithoutConstructor();
            (new \ReflectionMethod(MatchEngine::class, '__construct'))->invoke($engine, $state, new SeededRandom(1));

            return (new \ReflectionMethod(MatchEngine::class, 'ability'))->invoke($engine, 'home', 'build', Ability::LINES['passing']);
        };
        $base = LeagueMatch::state($f, 1);
        $this->assertSame(0, $base['pitch']);
        $abilities = [$ability($base)];
        foreach ([1, 2, 3] as $stage) {
            $this->stage('pitch', $stage);
            $state = LeagueMatch::state($f, 1);
            $this->assertSame($stage, $state['pitch']);
            $abilities[] = $ability($state);
        }
        // Each stage adds 1% of the line's ability on top of the base advantage.
        foreach ([1, 2, 3] as $stage) {
            $this->assertGreaterThan($abilities[$stage - 1], $abilities[$stage]);
        }
        $raw = Ability::lines($base['teams']['home'], 'build', Ability::LINES['passing']);
        $base = (int) config('game.match.home_base_bp');
        $this->assertSame(intdiv($raw * ($base + 600), 10000) - intdiv($raw * $base, 10000), $abilities[3] - $abilities[0]);
    }

    public function test_the_training_section_makes_every_session_faster(): void
    {
        foreach ([0, 1, 2, 3] as $stage) {
            $this->stage('training', $stage);
            [$lo, $hi] = config('game.stadium.training_speed_bp')[$stage];
            foreach (range(1, 50) as $i) {
                $step = Stadium::trainingStep($this->mine, 1000, "k{$i}");
                $this->assertTrue($step >= 1000 + intdiv($lo, 10) && $step <= 1000 + intdiv($hi, 10), "{$stage}: {$step}");
            }
        }
        // And it reaches the sessions themselves.
        $p = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.club_id', $this->mine)
            ->whereColumn('master_players.potential', '>', 'players.overall')->value('players.id');
        // [Sprint 21 E6] With the line's coach.
        $line = (string) DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.id', $p)->value('master_players.line');
        DB::table('staff_specialists')->insert(['club_id' => $this->mine, 'type' => Specialists::LINE_COACH[$line], 'cost' => 0, 'stars' => 1,
            'starts_at' => GameClock::now(), 'ends_at' => GameClock::now()->addYear(), 'idempotency_key' => 'test-coach']);
        Training::add($this->mine, $p);
        Carbon::setTestNow(GameClock::now()->addSeconds(Training::interval($this->league['id'])));
        Training::due();
        $this->assertGreaterThan(0, (int) DB::table('players')->where('id', $p)->value('training_progress'));
    }
}
