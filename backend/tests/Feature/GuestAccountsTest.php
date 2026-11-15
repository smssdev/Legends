<?php

namespace Tests\Feature;

use App\Auth\GoogleIdentity;
use App\Auth\GoogleTokenVerifier;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

/** [Sprint 50 M5] Playing as a guest, keeping the account (a username or Google), and the guests never kept deleted. */
class GuestAccountsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-11-10 10:00:00');
        $this->app->instance(GoogleTokenVerifier::class, new class extends GoogleTokenVerifier
        {
            public function __construct() {}

            public function verify(string $idToken): ?GoogleIdentity
            {
                return match ($idToken) {
                    'new' => new GoogleIdentity('g-new', 'new@example.com', true, 'Nour'),
                    'taken' => new GoogleIdentity('g-old', 'old@example.com', true, 'Old'),
                    default => null,
                };
            }
        });
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_a_guest_plays_then_keeps_the_account_with_a_username(): void
    {
        $res = $this->postJson('/api/v1/auth/guest', ['device_name' => 'Pixel'])->assertCreated()->assertJsonPath('user.guest', true)->assertJsonPath('user.role', 'user')->json();
        $this->assertNotEmpty($res['token']);
        $this->assertFalse($res['user']['has_password']);
        $auth = ['Authorization' => 'Bearer '.$res['token']];
        $this->getJson('/api/v1/auth/me', $auth)->assertOk()->assertJsonPath('user.guest', true);

        $this->postJson('/api/v1/auth/guest/keep', ['name' => 'سارة', 'username' => 'sara', 'password' => 'short'], $auth)->assertUnprocessable();
        $this->postJson('/api/v1/auth/guest/keep', ['name' => 'سارة', 'username' => 'sara', 'password' => 'Strong-pass-2026'], $auth)
            ->assertOk()->assertJsonPath('user.guest', false)->assertJsonPath('user.username', 'sara')->assertJsonPath('user.has_password', true);
        // The same account, now signed in with its password; kept once.
        $this->assertSame($res['user']['id'], User::where('username', 'sara')->value('id'));
        $this->postJson('/api/v1/auth/token', ['email' => 'sara', 'password' => 'Strong-pass-2026', 'device_name' => 'Pixel'])->assertOk();
        $this->postJson('/api/v1/auth/guest/keep', ['name' => 'سارة', 'username' => 'sara2', 'password' => 'Strong-pass-2026'], $auth)->assertConflict();
    }

    public function test_a_guest_keeps_the_account_with_google_unless_it_is_ours_already(): void
    {
        User::factory()->create(['google_id' => 'g-old', 'email' => 'old@example.com']);
        $token = $this->postJson('/api/v1/auth/guest', ['device_name' => 'Pixel'])->json('token');
        $auth = ['Authorization' => 'Bearer '.$token];
        $this->postJson('/api/v1/auth/guest/google', ['id_token' => 'taken'], $auth)->assertUnprocessable();
        $this->postJson('/api/v1/auth/guest/google', ['id_token' => 'new'], $auth)->assertOk()
            ->assertJsonPath('user.guest', false)->assertJsonPath('user.google', true)->assertJsonPath('user.email', 'new@example.com');
    }

    public function test_guests_never_kept_are_deleted_after_their_days(): void
    {
        $this->postJson('/api/v1/auth/guest', ['device_name' => 'A'])->assertCreated();
        $kept = $this->postJson('/api/v1/auth/guest', ['device_name' => 'B'])->json('token');
        $this->postJson('/api/v1/auth/guest/keep', ['name' => 'عمر', 'username' => 'omar', 'password' => 'Strong-pass-2026'], ['Authorization' => 'Bearer '.$kept])->assertOk();
        Carbon::setTestNow('2026-11-10 10:00:00');
        $this->artisan('guests:prune')->assertSuccessful();
        $this->assertSame(2, User::count());
        Carbon::setTestNow(Carbon::parse('2026-11-10 10:00:00')->addDays((int) config('game.account.guest_days') + 1));
        $this->artisan('guests:prune')->assertSuccessful();
        $this->assertSame(['omar'], User::pluck('username')->all());
    }
}
