<?php

namespace Tests\Feature;

use App\Admin\TwoFactor;
use App\Auth\GoogleIdentity;
use App\Auth\GoogleLinker;
use App\Models\User;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/** [UP5, UP6] The owner's spec (1): Google names the coach, and the welcome coins wait for the WhatsApp code. */
class AccountVerificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_the_welcome_coins_arrive_once_with_the_code_the_developer_issued(): void
    {
        config(['game.support.whatsapp' => '+20 100 000 0000']);
        $coach = User::factory()->create(['username' => 'karim']);
        $me = $this->actingAs($coach)->getJson('/api/v1/auth/me')->assertOk()->assertJsonPath('user.verification.verified', false)->json('user.verification');
        $this->assertStringStartsWith('https://wa.me/201000000000?text=', $me['whatsapp']);
        $this->assertStringContainsString(rawurlencode('karim'), $me['whatsapp']);
        $this->assertSame(0, Wallet::balance($coach->id));

        // A developer issues the code from the admin panel, after the second step.
        $admin = User::factory()->create(['role' => 'admin']);
        // The admin panel is the site's: a request from it carries a session (Sanctum's stateful domains).
        $this->withHeader('Referer', config('app.url'));
        $this->actingAs($coach)->postJson("/api/v1/admin/users/{$coach->id}/verification-code")->assertForbidden();
        $secret = $this->actingAs($admin)->postJson('/api/v1/admin/2fa/setup')->json('secret');
        $this->postJson('/api/v1/admin/2fa/confirm', ['code' => TwoFactor::engine()->getCurrentOtp($secret)])->assertOk();
        $old = $this->postJson("/api/v1/admin/users/{$coach->id}/verification-code")->assertOk()->json('code');
        $code = $this->postJson("/api/v1/admin/users/{$coach->id}/verification-code")->assertOk()->assertJsonPath('username', 'karim')->json('code');
        $this->assertMatchesRegularExpression('/^\d{6}$/', $code);

        // A wrong code, or the one the new code replaced, is refused; the right one verifies and pays, once.
        $this->actingAs($coach)->postJson('/api/v1/auth/verify-account', ['code' => '12345x'])->assertStatus(422);
        if ($old !== $code) {
            $this->postJson('/api/v1/auth/verify-account', ['code' => $old])->assertStatus(422);
        }
        $this->postJson('/api/v1/auth/verify-account', ['code' => $code])->assertOk()->assertJsonPath('user.verification.verified', true)->assertJsonPath('coins', 1000);
        $this->assertSame(1000, Wallet::balance($coach->id));
        $this->postJson('/api/v1/auth/verify-account', ['code' => $code])->assertConflict();
        $this->assertSame(1000, Wallet::balance($coach->id));
        $this->assertSame(Wallet::sum($coach->id), Wallet::balance($coach->id));
    }

    public function test_google_gives_the_name_the_picture_and_a_username_made_from_the_name(): void
    {
        $linker = app(GoogleLinker::class);
        $a = $linker->resolve(new GoogleIdentity('g1', 'x1@gmail.com', true, 'Ahmed Ali', 'https://lh3.googleusercontent.com/a/pic'));
        $b = $linker->resolve(new GoogleIdentity('g2', 'x2@gmail.com', true, 'Ahmed Ali'));
        $c = $linker->resolve(new GoogleIdentity('g3', 'zizo@gmail.com', true, 'أحمد علي'));
        $this->assertSame(['Ahmed Ali', 'ahmedali'], [$a->name, $a->username]);
        $this->assertSame('https://lh3.googleusercontent.com/a/pic', $a->toAccount()['avatar_url']);
        $this->assertNotSame('ahmedali', $b->username);
        $this->assertStringStartsWith('ahmedali', $b->username);
        $this->assertMatchesRegularExpression('/^[a-z][a-z0-9]{2,19}$/', $c->username);
        $this->assertSame('أحمد علي', $c->name);
    }
}
