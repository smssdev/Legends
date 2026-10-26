<?php

namespace Tests\Feature;

use App\League\ClubLedger;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** Private leagues, the way in, and the club money a handover needs [Sprint 13, PLAN 2.1, 2.3, 2.7]. */
class LeagueTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        // 12 real clubs: a league of 6 to 12 of them [UP9].
        $this->template(12);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_a_new_league_copies_the_strongest_clubs_funds_them_and_gives_the_owner_his_club(): void
    {
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['name' => '']);

        $this->assertMatchesRegularExpression('/^[A-HJ-NP-Z2-9]{8}$/', $league['code']);
        $this->assertSame('Test League #'.$league['code'], $league['name']);
        $this->assertSame(['waiting', false, true], [$league['status'], $league['locked'], $league['fair_league']]);
        // 6 teams: 10 rounds, and the last quarter (rounded up to 3) starts at round 8.
        $this->assertSame(['rounds' => 10, 'lock_from_round' => 8], array_intersect_key($league['season'], ['rounds' => 1, 'lock_from_round' => 1]));

        $clubs = DB::table('clubs')->where('league_id', $league['id'])->orderByDesc('strength_snapshot')->get();
        $this->assertSame(['Club 0', 'Club 1', 'Club 2', 'Club 3', 'Club 4', 'Club 5'], $clubs->pluck('name')->all());
        $this->assertSame(24, DB::table('players')->where('league_id', $league['id'])->count());
        foreach ($clubs as $club) {
            $this->assertSame(3_000_000, (int) $club->balance);
            $this->assertSame(3_000_000, ClubLedger::sum($club->id));
        }
        $this->assertSame($clubs[0]->id, $league['my_club_id']);
        $this->assertSame($owner->id, (int) $clubs[0]->user_id);
        $this->assertSame(1, DB::table('league_memberships')->where('league_id', $league['id'])->whereNull('left_at')->count());

        $mine = $this->actingAs($owner)->getJson('/api/v1/leagues')->assertOk();
        $mine->assertJsonPath('active_teams', 1)->assertJsonPath('leagues.0.id', $league['id']);
    }

    public function test_the_settings_must_stay_within_their_limits(): void
    {
        $owner = User::factory()->create();
        $this->actingAs($owner)->withoutMiddleware(ThrottleRequests::class);
        foreach ([
            // [UP9, UP17] Half the real league's 12 clubs at least; 2, 4 or 6 days to get ready; one round a day.
            'team_count' => [5, 13], 'starting_budget' => [999_999, 10_000_001], 'prep_days' => [1, 3, 7], 'rounds_per_day' => [2],
            'season_end_mode' => ['forever'], 'starts_at' => [GameClock::now()->addDays(8)->toIso8601ZuluString(), GameClock::now()->subHour()->toIso8601ZuluString()],
        ] as $field => $bad) {
            foreach ($bad as $value) {
                $this->postJson('/api/v1/leagues', $this->settings([$field => $value]))->assertUnprocessable()->assertJsonValidationErrors($field);
            }
        }
        $this->postJson('/api/v1/leagues', $this->settings(['round_times' => ['18:00', '21:00']]))->assertJsonValidationErrors('round_times');
        $this->postJson('/api/v1/leagues', $this->settings(['team_count' => 12, 'template' => 'Nowhere']))->assertUnprocessable();
        // The owner's club must be one of the N copied.
        $weak = DB::table('master_clubs')->where('name', 'Club 10')->value('id');
        $this->postJson('/api/v1/leagues', $this->settings(['club_id' => $weak]))->assertUnprocessable()->assertJsonPath('message', 'اختر فريقك من أندية هذا الدوري.');
        $this->assertSame(0, DB::table('leagues')->count());

        // The edges are fine: 6 and 12 teams, 1 and 10 million.
        $this->makeLeague($owner, ['team_count' => 6, 'starting_budget' => 1_000_000]);
        $this->makeLeague($owner, ['team_count' => 12, 'starting_budget' => 10_000_000, 'rounds_per_day' => 1, 'round_times' => ['20:00']]);
    }

    public function test_join_by_code_wait_for_the_owner_then_take_a_free_club(): void
    {
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner);
        $coach = User::factory()->create();

        $this->actingAs($coach)->postJson('/api/v1/leagues/join', ['code' => 'ZZZZZZZZ'])->assertNotFound()->assertJsonPath('message', 'لا يوجد دوري بهذا الكود.');
        // Lower case, spaces and a # are forgiven.
        $asked = $this->postJson('/api/v1/leagues/join', ['code' => '#'.strtolower(substr($league['code'], 0, 4)).' '.substr($league['code'], 4)])
            ->assertCreated()->assertJsonPath('request.status', 'pending')->assertJsonPath('league.code', null);
        $this->postJson('/api/v1/leagues/join', ['code' => $league['code']])->assertOk()->assertJsonPath('request.id', $asked->json('request.id'));
        $this->getJson("/api/v1/leagues/{$league['id']}")->assertOk()->assertJsonPath('league.my_request', 'pending');
        $this->getJson("/api/v1/leagues/{$league['id']}/clubs")->assertForbidden();
        $this->postJson("/api/v1/leagues/{$league['id']}/clubs/{$this->botClub($league['id'])}/claim")->assertForbidden();
        $this->getJson("/api/v1/leagues/{$league['id']}/requests")->assertForbidden();

        $this->actingAs($owner)->getJson("/api/v1/leagues/{$league['id']}/requests")->assertOk()->assertJsonPath('requests.0.user.name', $coach->name);
        $this->postJson("/api/v1/leagues/{$league['id']}/requests/{$asked->json('request.id')}/approve")->assertOk()->assertJsonPath('request.status', 'approved');
        $this->postJson("/api/v1/leagues/{$league['id']}/requests/{$asked->json('request.id')}/reject")->assertConflict();

        // Approved: every club with its data, the owner's shown as taken.
        $clubs = $this->actingAs($coach)->getJson("/api/v1/leagues/{$league['id']}/clubs")->assertOk()->json('clubs');
        $this->assertCount(6, $clubs);
        $this->assertSame([false, $owner->name], [$clubs[0]['bot'], $clubs[0]['coach']['name']]);
        $this->assertSame([true, 3_000_000, 4_000_004], [$clubs[1]['bot'], $clubs[1]['balance'], $clubs[1]['squad_value']]);
        $this->getJson("/api/v1/leagues/{$league['id']}/clubs/{$clubs[1]['id']}")->assertOk()->assertJsonCount(4, 'players')->assertJsonPath('players.0.line', 'gk');

        $this->postJson("/api/v1/leagues/{$league['id']}/clubs/{$clubs[0]['id']}/claim")->assertConflict()->assertJsonPath('message', 'الفريق أُخذ، اختر فريقاً آخر.');
        $this->postJson("/api/v1/leagues/{$league['id']}/clubs/{$clubs[1]['id']}/claim")->assertCreated()->assertJsonPath('club.coach.id', $coach->id);
        $this->getJson("/api/v1/leagues/{$league['id']}")->assertJsonPath('league.my_club_id', $clubs[1]['id'])->assertJsonPath('league.code', $league['code']);

        $this->actingAs($owner)->getJson("/api/v1/leagues/{$league['id']}")->assertJsonPath('league.free_clubs', 4)->assertJsonPath('league.pending_requests', 0);

        // A waiting request can be taken back, and sent again.
        $shy = User::factory()->create();
        $this->actingAs($shy)->postJson('/api/v1/leagues/join', ['code' => $league['code']])->assertCreated();
        $this->actingAs($owner)->getJson("/api/v1/leagues/{$league['id']}")->assertJsonPath('league.pending_requests', 1);
        $this->actingAs($shy)->deleteJson("/api/v1/leagues/{$league['id']}/request")->assertOk();
        $this->deleteJson("/api/v1/leagues/{$league['id']}/request")->assertNotFound();
        $this->getJson("/api/v1/leagues/{$league['id']}")->assertNotFound();
        $this->postJson('/api/v1/leagues/join', ['code' => $league['code']])->assertCreated();

        // A rejected request stays rejected.
        $other = User::factory()->create();
        $id = $this->actingAs($other)->postJson('/api/v1/leagues/join', ['code' => $league['code']])->json('request.id');
        $this->actingAs($owner)->postJson("/api/v1/leagues/{$league['id']}/requests/{$id}/reject")->assertOk();
        $this->actingAs($other)->postJson('/api/v1/leagues/join', ['code' => $league['code']])->assertConflict()->assertJsonPath('message', 'رفض منشئ الدوري طلبك.');
        $this->getJson("/api/v1/leagues/{$league['id']}")->assertNotFound();
    }

    public function test_one_club_per_league_and_the_owner_cannot_ask_to_join(): void
    {
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner);
        $this->actingAs($owner)->postJson('/api/v1/leagues/join', ['code' => $league['code']])->assertConflict();
        $this->postJson("/api/v1/leagues/{$league['id']}/clubs/{$this->botClub($league['id'])}/claim")->assertConflict()->assertJsonPath('message', 'لديك فريق في هذا الدوري.');

        $coach = $this->approvedCoach($owner, $league);
        $this->actingAs($coach)->postJson("/api/v1/leagues/{$league['id']}/clubs/{$this->botClub($league['id'])}/claim")->assertCreated();
        $this->postJson("/api/v1/leagues/{$league['id']}/clubs/{$this->botClub($league['id'])}/claim")->assertConflict();
        $this->assertSame(1, DB::table('clubs')->where('league_id', $league['id'])->where('user_id', $coach->id)->count());
    }

    public function test_active_teams_stop_at_the_limit(): void
    {
        // The limit is 10 (the coach's slots, X18); a smaller one keeps the test short, the rule is the same.
        config(['game.league.max_active_teams' => 4]);
        $user = User::factory()->create();
        $leagues = [];
        for ($i = 0; $i < 3; $i++) {
            $leagues[] = $this->makeLeague($user);
        }
        $other = $this->makeLeague(User::factory()->create());
        $coach = $this->approvedCoach(User::find($other['owner']['id']), $other);
        $this->assertNotNull($coach);
        // A fourth through joining.
        $id = $this->actingAs($user)->postJson('/api/v1/leagues/join', ['code' => $other['code']])->json('request.id');
        $this->actingAs(User::find($other['owner']['id']))->postJson("/api/v1/leagues/{$other['id']}/requests/{$id}/approve")->assertOk();
        $this->actingAs($user)->postJson("/api/v1/leagues/{$other['id']}/clubs/{$this->botClub($other['id'])}/claim")->assertCreated();
        $this->getJson('/api/v1/leagues')->assertJsonPath('active_teams', 4);

        $this->postJson('/api/v1/leagues', $this->settings())->assertConflict()->assertJsonPath('message', 'وصلت للحد: 4 فرق نشطة في وقت واحد.');
        $fifth = $this->makeLeague(User::factory()->create());
        $this->actingAs($user)->postJson('/api/v1/leagues/join', ['code' => $fifth['code']])->assertConflict();

        // A finished league frees its seat.
        DB::table('leagues')->where('id', $leagues[0]['id'])->update(['status' => 'finished']);
        $this->actingAs($user)->postJson('/api/v1/leagues/join', ['code' => $fifth['code']])->assertCreated();
    }

    public function test_no_one_comes_in_during_the_last_quarter_of_the_league_rounds(): void
    {
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner);
        $coach = $this->approvedCoach($owner, $league);
        $late = User::factory()->create();

        // 6 of 10 played: the next round is 7, still open.
        DB::table('seasons')->where('league_id', $league['id'])->update(['rounds_played' => 6]);
        $this->actingAs($owner)->getJson("/api/v1/leagues/{$league['id']}")->assertJsonPath('league.season.join_open', true);
        // 7 played: the next round (8) is in the last quarter.
        DB::table('seasons')->where('league_id', $league['id'])->update(['rounds_played' => 7]);
        $this->getJson("/api/v1/leagues/{$league['id']}")->assertJsonPath('league.season.join_open', false);
        $this->actingAs($late)->postJson('/api/v1/leagues/join', ['code' => $league['code']])->assertConflict()->assertJsonPath('message', 'الانضمام مقفل في آخر ربع من جولات الدوري.');
        $this->actingAs($coach)->postJson("/api/v1/leagues/{$league['id']}/clubs/{$this->botClub($league['id'])}/claim")->assertConflict();
        $this->assertNull(DB::table('clubs')->where('user_id', $coach->id)->value('id'));
    }

    public function test_a_coach_who_left_cannot_come_back_the_same_season(): void
    {
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner);
        $coach = $this->approvedCoach($owner, $league);
        $club = $this->botClub($league['id']);
        $this->actingAs($coach)->postJson("/api/v1/leagues/{$league['id']}/clubs/{$club}/claim")->assertCreated();
        // Leaving (Sprint 14 builds resigning and kicking): the club goes back to the bots.
        DB::table('league_memberships')->where('user_id', $coach->id)->update(['left_at' => GameClock::now(), 'left_reason' => 'resigned']);
        DB::table('clubs')->where('id', $club)->update(['user_id' => null]);

        $this->postJson("/api/v1/leagues/{$league['id']}/clubs/{$club}/claim")->assertConflict()
            ->assertJsonPath('message', 'غادرت هذا الدوري هذا الموسم، ويمكنك العودة في الموسم الجديد.');
        $this->assertSame(0, DB::table('league_memberships')->where('user_id', $coach->id)->whereNull('left_at')->count());
    }

    public function test_a_club_taken_from_a_bot_keeps_between_half_a_million_and_the_starting_budget(): void
    {
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner);
        [$rich, $poor, $fair] = DB::table('clubs')->where('league_id', $league['id'])->whereNull('user_id')->orderBy('id')->limit(3)->pluck('id')->all();
        ClubLedger::post($rich, 'opening', 2_000_000, 'test:rich');        // 5,000,000
        ClubLedger::post($poor, 'opening', -2_800_000, 'test:poor');       //   200,000
        ClubLedger::post($fair, 'opening', -1_000_000, 'test:fair');       // 2,000,000

        foreach ([$rich => 3_000_000, $poor => 500_000, $fair => 2_000_000] as $club => $after) {
            $coach = $this->approvedCoach($owner, $league);
            $this->actingAs($coach)->postJson("/api/v1/leagues/{$league['id']}/clubs/{$club}/claim")->assertCreated()->assertJsonPath('club.balance', $after);
            $this->assertSame($after, ClubLedger::sum($club));
        }
        $this->assertSame(['handover_trim' => -2_000_000, 'handover_gift' => 300_000],
            DB::table('club_transactions')->where('type', 'like', 'handover%')->pluck('amount', 'type')->map(fn ($a) => (int) $a)->all());

        // A league that starts with 1,000,000: the ceiling is its own starting budget.
        $small = $this->makeLeague(User::factory()->create(), ['starting_budget' => 1_000_000]);
        $club = $this->botClub($small['id']);
        ClubLedger::post($club, 'opening', 500_000, 'test:small');
        $coach = $this->approvedCoach(User::find($small['owner']['id']), $small);
        $this->actingAs($coach)->postJson("/api/v1/leagues/{$small['id']}/clubs/{$club}/claim")->assertCreated()->assertJsonPath('club.balance', 1_000_000);
    }

    public function test_the_ledger_posts_each_key_once_and_never_spends_money_it_does_not_have(): void
    {
        $league = $this->makeLeague(User::factory()->create());
        $club = $this->botClub($league['id']);

        $this->assertSame(3_500_000, ClubLedger::post($club, 'opening', 500_000, 'test:once'));
        $this->assertSame(3_500_000, ClubLedger::post($club, 'opening', 500_000, 'test:once'));
        $this->assertSame(2, DB::table('club_transactions')->where('club_id', $club)->count());

        try {
            ClubLedger::post($club, 'opening', -3_600_000, 'test:spend', spend: true);
            $this->fail('Spent more than the balance.');
        } catch (HttpException $e) {
            $this->assertSame(409, $e->getStatusCode());
        }
        // Without $spend (wages, later) it may go below zero, and then nothing can be spent.
        $this->assertSame(-100_000, ClubLedger::post($club, 'opening', -3_600_000, 'test:wages'));
        $this->expectException(HttpException::class);
        try {
            ClubLedger::post($club, 'opening', -1, 'test:debt', spend: true);
        } finally {
            $this->assertSame(-100_000, ClubLedger::sum($club));
            $this->assertSame(-100_000, (int) DB::table('clubs')->where('id', $club)->value('balance'));
        }
    }

    public function test_a_reused_key_for_another_movement_is_a_bug(): void
    {
        $league = $this->makeLeague(User::factory()->create());
        $this->expectException(\LogicException::class);
        ClubLedger::post($this->botClub($league['id']), 'opening', 1, "opening:{$this->botClub($league['id'])}:1");
    }

    public function test_settings_change_until_the_start_and_are_locked_after_it(): void
    {
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner);
        $coach = $this->approvedCoach($owner, $league);

        $this->actingAs($coach)->patchJson("/api/v1/leagues/{$league['id']}", ['name' => 'X'])->assertForbidden();
        $this->actingAs($owner)->patchJson("/api/v1/leagues/{$league['id']}", ['name' => 'دوري الشلة', 'fair_league' => false, 'rounds_per_day' => 1, 'round_times' => ['20:30']])
            ->assertOk()->assertJsonPath('league.name', 'دوري الشلة')->assertJsonPath('league.fair_league', false)->assertJsonPath('league.round_times', ['20:30']);
        $this->patchJson("/api/v1/leagues/{$league['id']}", ['round_times' => ['18:00', '21:00']])->assertJsonValidationErrors('round_times');

        // The scheduler starts it on time.
        Carbon::setTestNow(GameClock::now()->addDay()->addMinute());
        $this->artisan('leagues:start')->assertSuccessful();
        $this->getJson("/api/v1/leagues/{$league['id']}")->assertJsonPath('league.status', 'running')->assertJsonPath('league.locked', true)
            ->assertJsonPath('league.season.status', 'running');
        $this->patchJson("/api/v1/leagues/{$league['id']}", ['name' => 'Y'])->assertConflict()->assertJsonPath('message', 'إعدادات الدوري مقفلة منذ بدايته.');
        $this->postJson("/api/v1/leagues/{$league['id']}/start")->assertConflict();

        // Joining is still open after the start (until the last quarter).
        $this->assertNotNull($this->approvedCoach($owner, $league));
    }

    public function test_start_now_in_development(): void
    {
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['is_dev' => true]);
        $this->assertTrue($league['is_dev']);
        $this->actingAs(User::factory()->create())->postJson("/api/v1/leagues/{$league['id']}/start")->assertForbidden();
        $started = $this->actingAs($owner)->postJson("/api/v1/leagues/{$league['id']}/start")->assertOk()->assertJsonPath('league.locked', true)->json('league');
        $this->assertSame(GameClock::now()->toIso8601ZuluString(), $started['starts_at']);

        $this->app['env'] = 'production';
        $other = $this->makeLeague($owner, ['is_dev' => true]);
        $this->assertFalse($other['is_dev']);
        $this->postJson("/api/v1/leagues/{$other['id']}/start")->assertNotFound();
    }

    public function test_league_codes_are_rate_limited(): void
    {
        $this->actingAs(User::factory()->create());
        for ($i = 0; $i < 10; $i++) {
            $this->postJson('/api/v1/leagues/join', ['code' => 'ABCDEFG'.$i])->assertNotFound();
        }
        $this->postJson('/api/v1/leagues/join', ['code' => 'ABCDEFGH'])->assertStatus(429);
    }

    public function test_a_deleted_account_hands_its_club_back_to_the_bots(): void
    {
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner);
        $coach = $this->approvedCoach($owner, $league);
        $club = $this->botClub($league['id']);
        $this->actingAs($coach)->postJson("/api/v1/leagues/{$league['id']}/clubs/{$club}/claim")->assertCreated();

        $this->deleteJson('/api/v1/auth/me', ['password' => 'password', 'phrase' => 'احذف'])->assertOk();
        $this->assertNull(DB::table('clubs')->where('id', $club)->value('user_id'));
        $this->assertSame('deleted', DB::table('league_memberships')->where('club_id', $club)->value('left_reason'));
    }

    public function test_leagues_need_an_account_and_stay_private(): void
    {
        $league = $this->makeLeague(User::factory()->create());
        $this->app['auth']->forgetGuards();
        $this->getJson('/api/v1/leagues')->assertUnauthorized();
        $this->actingAs(User::factory()->create())->getJson("/api/v1/leagues/{$league['id']}")->assertNotFound();
        $this->getJson("/api/v1/leagues/{$league['id']}/clubs")->assertNotFound();
    }
}
