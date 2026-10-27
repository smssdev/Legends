<?php

namespace Tests\Feature;

use App\Admin\TwoFactor;
use App\League\ClubLedger;
use App\Messages\Inbox;
use App\Models\User;
use App\Support\Activity;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** Running the game [Sprint 37]: deleting an account, the deploy's wait, the admin panel and its second step. */
class OperationsTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_deleting_an_active_account_leaves_nothing_of_it_and_its_team_plays_on_as_a_bot(): void
    {
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 4]);
        $coach = User::factory()->create(['password' => bcrypt('secret123')]);
        $join = $this->actingAs($coach)->postJson('/api/v1/leagues/join', ['code' => $league['code']])->json('request.id');
        $this->actingAs($owner)->postJson("/api/v1/leagues/{$league['id']}/requests/{$join}/approve")->assertOk();
        $club = $this->botClub($league['id']);
        $this->actingAs($coach)->postJson("/api/v1/leagues/{$league['id']}/clubs/{$club}/claim")->assertCreated();
        // Everything a coach has: a title, an objective judged, coins, a pending offer, a listing, messages, a device, activity.
        $season = DB::table('seasons')->where('league_id', $league['id'])->value('id');
        DB::table('titles')->insert(['league_id' => $league['id'], 'season_id' => $season, 'user_id' => $coach->id, 'club_id' => $club, 'competition' => 'cup', 'position' => 1]);
        DB::table('club_objectives')->where('club_id', $club)->update(['user_id' => $coach->id, 'achieved' => true]);
        Wallet::post($coach->id, 'daily', 10, 'd');
        $theirs = DB::table('players')->where('club_id', $league['my_club_id'])->value('id');
        $offer = DB::table('transfer_offers')->insertGetId(['league_id' => $league['id'], 'season_id' => $season, 'from_club_id' => $club, 'to_club_id' => $league['my_club_id'], 'money' => 1000,
            'status' => 'pending', 'expires_at' => GameClock::now()->addDay(), 'idempotency_key' => 'o1', 'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        DB::table('transfer_listings')->insert(['club_id' => $club, 'player_id' => DB::table('players')->where('club_id', $club)->value('id'), 'price' => 1000, 'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        Inbox::send($coach->id, 'training_done', ['player' => 'X', 'overall' => 70]);
        DB::table('push_subscriptions')->insert(['user_id' => $coach->id, 'endpoint' => 'https://push.example/x', 'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        Activity::record($coach->id, 'visits');

        $this->actingAs($coach)->deleteJson('/api/v1/auth/me', ['password' => 'secret123', 'phrase' => 'احذف'])->assertOk();

        // No table keeps a row that points at the account.
        foreach (array_column(Schema::getTables(), 'name') as $t) {
            if (Schema::hasColumn($t, 'user_id')) {
                $this->assertSame(0, DB::table($t)->where('user_id', $coach->id)->count(), $t);
            }
        }
        $this->assertNull(DB::table('users')->find($coach->id));
        // The club is a bot again, with its deals cancelled; the league keeps the title, without the name.
        $this->assertNull(DB::table('clubs')->where('id', $club)->value('user_id'));
        $this->assertSame('cancelled', DB::table('transfer_offers')->where('id', $offer)->value('status'));
        $this->assertSame(0, DB::table('transfer_listings')->where('club_id', $club)->count());
        $this->assertSame(1, DB::table('titles')->where('club_id', $club)->whereNull('user_id')->count());
        $this->assertGreaterThan(0, ClubLedger::sum($club));
    }

    public function test_the_deploy_waits_for_live_matches_and_those_about_to_start(): void
    {
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 4, 'rounds_per_day' => 1, 'round_times' => ['21:00']]);
        $first = DB::table('fixtures')->where('is_bye', false)->whereNotNull('home_id')->orderBy('scheduled_at')->first();
        Carbon::setTestNow(Carbon::parse($first->scheduled_at, 'UTC')->subMinutes(30));
        $this->artisan('matches:live --soon=15')->expectsOutput('0')->assertSuccessful();
        Carbon::setTestNow(Carbon::parse($first->scheduled_at, 'UTC')->subMinutes(10));
        $this->artisan('matches:live')->expectsOutput('0')->assertSuccessful();
        $this->assertSame(0, (int) DB::table('matches')->count());
        $soon = DB::table('fixtures')->where('scheduled_at', $first->scheduled_at)->where('is_bye', false)->whereNotNull('home_id')->count();
        $this->artisan('matches:live --soon=15')->expectsOutput((string) $soon)->assertSuccessful();
    }

    public function test_without_the_two_step_code_the_panel_opens_for_an_admin_at_once(): void
    {
        // [X46] The owner's decision: no code asked (game.admin.two_factor off by default).
        $user = User::factory()->create();
        $admin = User::factory()->create(['role' => 'admin']);
        $this->withHeader('Referer', config('app.url'));
        $this->actingAs($user)->getJson('/api/v1/admin/overview')->assertForbidden();
        $this->actingAs($admin)->getJson('/api/v1/admin/2fa')->assertOk()->assertJsonPath('required', false)->assertJsonPath('passed', true);
        $this->actingAs($admin)->getJson('/api/v1/admin/overview')->assertOk();
    }

    public function test_the_admin_panel_is_for_the_admin_after_the_two_step_code(): void
    {
        config(['game.admin.two_factor' => true]);
        $user = User::factory()->create();
        $admin = User::factory()->create(['role' => 'admin']);
        // From the site: Sanctum's session (the second step is kept in it).
        $this->withHeader('Referer', config('app.url'));
        $this->actingAs($user)->getJson('/api/v1/admin/overview')->assertForbidden();
        $this->actingAs($admin)->getJson('/api/v1/admin/overview')->assertStatus(423);
        // Set up: a secret, then a code from it.
        $secret = $this->actingAs($admin)->postJson('/api/v1/admin/2fa/setup')->assertOk()->json('secret');
        $this->postJson('/api/v1/admin/2fa/confirm', ['code' => '000000'])->assertUnprocessable();
        $this->postJson('/api/v1/admin/2fa/confirm', ['code' => TwoFactor::engine()->getCurrentOtp($secret)])->assertOk()->assertJsonPath('passed', true);
        $this->postJson('/api/v1/admin/2fa/setup')->assertConflict();
        Activity::record($user->id, 'visits');
        Activity::record($user->id, 'matches_watched');
        $this->getJson('/api/v1/admin/overview')->assertOk()->assertJsonPath('users', 2)->assertJsonPath('active_today', 2);
        $this->getJson('/api/v1/admin/users')->assertOk()->assertJsonCount(2, 'users');
        $this->getJson('/api/v1/admin/leagues')->assertOk();
        $this->getJson('/api/v1/admin/commentary')->assertOk();
        // [X33] Whether a deploy is safe now, and a backup to download off the server.
        $this->getJson('/api/v1/admin/overview')->assertJsonPath('deploy.busy', 0)->assertJsonPath('deploy.next_kickoff', null);
        $name = $this->postJson('/api/v1/admin/backups')->assertOk()->json('backups.0.name');
        $download = $this->get("/api/v1/admin/backups/$name/download")->assertOk();
        // The game's database file, or on PostgreSQL (Supabase, X43) its rows in one gzipped file.
        $this->assertStringStartsWith(DB::getDriverName() === 'pgsql' ? "\x1f\x8b" : 'SQLite format 3', (string) file_get_contents($download->baseResponse->getFile()->getPathname()));
        $this->get('/api/v1/admin/backups/2020-01-01_000000/download')->assertNotFound();
        $this->get('/api/v1/admin/backups/..%2F..%2F.env/download')->assertNotFound();
        // Hours later the code is asked again.
        Carbon::setTestNow(GameClock::now()->addHours(13));
        $this->getJson('/api/v1/admin/overview')->assertStatus(423);
        $this->postJson('/api/v1/admin/2fa/verify', ['code' => TwoFactor::engine()->getCurrentOtp($secret)])->assertOk();
        $this->getJson('/api/v1/admin/overview')->assertOk();
    }

    public function test_the_return_indicator_counts_who_came_back_the_next_week(): void
    {
        $a = User::factory()->create();
        $b = User::factory()->create();
        Carbon::setTestNow('2026-10-14 10:00:00');
        Activity::record($a->id, 'visits');
        Activity::record($b->id, 'visits');
        Carbon::setTestNow('2026-10-22 10:00:00');
        Activity::record($a->id, 'matches_watched');
        $now = Activity::weeks()[0];
        $this->assertSame(['active' => 1, 'returning' => 1, 'live' => 1], array_intersect_key($now, ['active' => 1, 'returning' => 1, 'live' => 1]));
        $this->assertSame(2, Activity::weeks()[1]['active']);
    }
}
