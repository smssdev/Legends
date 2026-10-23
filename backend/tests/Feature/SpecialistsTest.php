<?php

namespace Tests\Feature;

use App\League\ClubLedger;
use App\League\LeagueMatch;
use App\League\MatchResult;
use App\Models\User;
use App\Staff\Specialists;
use App\Support\GameClock;
use App\Training\SecretTraining;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** Specialists, item by item of docs/features/specialists.md [Sprint 31]. */
class SpecialistsTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    private int $mine;

    private object $fixture;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'rounds_per_day' => 1, 'round_times' => ['21:00']]);
        $this->mine = $this->league['my_club_id'];
        $this->fixture = SecretTraining::nextFixture($this->mine);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function hire(string $type, string $key = 'k1')
    {
        return $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/specialists", ['type' => $type, 'idempotency_key' => $key]);
    }

    private function squad(): array
    {
        return DB::table('players')->where('club_id', $this->mine)->orderBy('id')->pluck('id')->all();
    }

    /** What a finished match does to my players: the first eleven played, the rest rested; these events happened. */
    private function afterMatch(array $events, int $seed = 7): void
    {
        $ids = $this->squad();
        $matchId = DB::table('matches')->insertGetId(['fixture_id' => $this->fixture->id, 'seed' => $seed, 'engine_version' => 1, 'config_snapshot' => '{}',
            'initial_state' => '{}', 'state' => '{}', 'mode' => 'instant', 'status' => 'finished', 'started_at' => GameClock::now()]);
        foreach ($events as [$type, $player, $payload]) {
            DB::table('match_events')->insert(['match_id' => $matchId, 'tick' => 10, 'minute' => 10, 'type' => $type, 'club_id' => $this->mine,
                'player_id' => $player, 'payload' => json_encode($payload + ['player' => $player])]);
        }
        $team = ['players' => array_map(fn ($id, $i) => ['id' => $id, 'on' => $i < 11, 'out' => '', 'fit' => 7000], $ids, array_keys($ids))];
        (new \ReflectionMethod(MatchResult::class, 'players'))->invoke(null, $this->mine, $team, $seed, $matchId);
        DB::table('matches')->where('id', $matchId)->delete();
    }

    public function test_1_hiring_pays_once_one_of_a_kind_and_ends_on_time(): void
    {
        $before = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        $this->hire('doctor')->assertOk()->assertJsonPath('specialists.0.type', 'doctor');
        $this->hire('doctor')->assertOk();
        $this->assertSame($before - Specialists::cost($this->league['id'], 'doctor'), (int) DB::table('clubs')->where('id', $this->mine)->value('balance'));
        $this->hire('doctor', 'k2')->assertConflict()->assertJsonPath('message', 'لديك هذا الأخصائي الآن، جدّد عقده بعد أن ينتهي.');
        $this->hire('lawyer', 'k3')->assertOk();

        $seconds = Specialists::seconds($this->league['id']);
        $this->assertSame(intdiv(7 * 86400 * (int) DB::table('leagues')->where('id', $this->league['id'])->value('timer_scale'), 10000), $seconds);
        Carbon::setTestNow(GameClock::now()->addSeconds($seconds - 1));
        $this->assertTrue(Specialists::has($this->mine, 'doctor'));
        Carbon::setTestNow(GameClock::now()->addSeconds(1));
        $this->assertFalse(Specialists::has($this->mine, 'doctor'));
        $this->hire('doctor', 'k4')->assertOk();

        ClubLedger::post($this->mine, 'wages', -100_000_000, 'debt');
        $this->hire('physio', 'k5')->assertConflict()->assertJsonPath('message', 'رصيد النادي لا يكفي.');
    }

    public function test_2_the_doctor_brings_the_injured_back_sooner(): void
    {
        $hurt = $this->squad()[15];
        DB::table('players')->where('id', $hurt)->update(['injured_matches' => 3]);
        $this->afterMatch([]);
        $this->assertSame(2, (int) DB::table('players')->where('id', $hurt)->value('injured_matches'));
        $this->hire('doctor')->assertOk();
        $this->afterMatch([]);
        $this->assertSame(0, (int) DB::table('players')->where('id', $hurt)->value('injured_matches'));
    }

    public function test_3_the_lawyer_cancels_about_half_the_bans_and_always_the_same_ones(): void
    {
        $cancelled = 0;
        foreach (range(1, 400) as $seed) {
            $cancelled += Specialists::lawyerCancels($seed, 5) ? 1 : 0;
            $this->assertSame(Specialists::lawyerCancels($seed, 5), Specialists::lawyerCancels($seed, 5));
        }
        $this->assertTrue($cancelled > 160 && $cancelled < 240, (string) $cancelled);

        $red = $this->squad()[3];
        $seed = collect(range(1, 50))->first(fn ($s) => Specialists::lawyerCancels($s, $red));
        $this->afterMatch([['card', $red, ['color' => 'red']]], $seed);
        $this->assertSame(1, (int) DB::table('players')->where('id', $red)->value('suspended_matches'));
        DB::table('players')->where('id', $red)->update(['suspended_matches' => 0]);
        $this->hire('lawyer')->assertOk();
        $this->afterMatch([['card', $red, ['color' => 'red']]], $seed);
        $this->assertSame(0, (int) DB::table('players')->where('id', $red)->value('suspended_matches'));
    }

    public function test_4_the_keeper_coach_lifts_the_keeper_alone(): void
    {
        $this->hire('keeper_coach')->assertOk();
        Carbon::setTestNow(Carbon::parse($this->fixture->scheduled_at, 'UTC')->subMinutes(5));
        $this->artisan('matches:prepare')->assertSuccessful();
        // A week scaled to the development league may be shorter than the wait: hire again if it ran out.
        if (! Specialists::has($this->mine, 'keeper_coach')) {
            $this->hire('keeper_coach', 'k2')->assertOk();
        }
        $state = LeagueMatch::state(DB::table('fixtures')->find($this->fixture->id), 1);
        $side = $this->fixture->home_id === $this->mine ? 'home' : 'away';
        $base = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.club_id', $this->mine)
            ->get(['players.id', 'players.overall', 'master_players.line'])->keyBy('id');
        foreach ($state['teams'][$side]['players'] as $p) {
            $b = $base[$p['id']];
            $this->assertSame($b->line === 'gk' ? $b->overall + 2 : (int) $b->overall, $p['a']['ovr'], $b->line);
        }
    }

    public function test_5_the_physio_gives_a_resting_player_more(): void
    {
        $rested = $this->squad()[14];
        DB::table('players')->where('id', $rested)->update(['fitness' => 40]);
        $this->afterMatch([]);
        $this->assertSame(70, (int) DB::table('players')->where('id', $rested)->value('fitness'));
        DB::table('players')->where('id', $rested)->update(['fitness' => 40]);
        $this->hire('physio')->assertOk();
        $this->afterMatch([]);
        $this->assertSame(85, (int) DB::table('players')->where('id', $rested)->value('fitness'));
    }
}
