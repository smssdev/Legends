<?php

namespace Tests\Feature;

use App\Auth\GoogleIdentity;
use App\Auth\GoogleLinker;
use App\Auth\GoogleTokenVerifier;
use App\Models\User;
use Firebase\JWT\JWT;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Tests\TestCase;

/** Google sign-in must never hand an account to someone who registered a victim's email first [PLAN 2.17]. */
class GoogleSignInTest extends TestCase
{
    use RefreshDatabase;

    private \OpenSSLAsymmetricKey $key;

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.google.audiences' => ['web-client.apps.googleusercontent.com', 'android-client.apps.googleusercontent.com']]);
        $this->key = openssl_pkey_new(['private_key_bits' => 2048, 'private_key_type' => OPENSSL_KEYTYPE_RSA]);
        $d = openssl_pkey_get_details($this->key)['rsa'];
        $b64 = fn ($v) => rtrim(strtr(base64_encode($v), '+/', '-_'), '=');
        $jwks = ['keys' => [['kty' => 'RSA', 'alg' => 'RS256', 'use' => 'sig', 'kid' => 'test', 'n' => $b64($d['n']), 'e' => $b64($d['e'])]]];
        // Google's keys, without the network
        $this->app->instance(GoogleTokenVerifier::class, new class($jwks) extends GoogleTokenVerifier
        {
            public function __construct(private array $jwks) {}

            protected function keys(): array
            {
                return $this->jwks;
            }
        });
    }

    private function idToken(array $claims = []): string
    {
        openssl_pkey_export($this->key, $pem);

        return JWT::encode(array_merge([
            'iss' => 'https://accounts.google.com', 'aud' => 'android-client.apps.googleusercontent.com', 'sub' => 'google-victim',
            'email' => 'victim@example.com', 'email_verified' => true, 'name' => 'Victim', 'iat' => time(), 'exp' => time() + 3600,
        ], $claims), $pem, 'RS256', 'test');
    }

    private function google(array $claims = [])
    {
        return $this->postJson('/api/v1/auth/google/token', ['id_token' => $this->idToken($claims), 'device_name' => 'Pixel']);
    }

    public function test_hijack_an_unconfirmed_account_made_with_the_victims_email_loses_every_way_in(): void
    {
        // The attacker registers the victim's email with a password, never confirms it, and keeps a token.
        $attacker = User::create(['name' => 'Attacker', 'email' => 'victim@example.com', 'password' => 'attacker1']);
        $stolen = $attacker->createToken('attacker')->plainTextToken;
        DB::table('sessions')->insert(['id' => 's1', 'user_id' => $attacker->id, 'payload' => '', 'last_activity' => 0]);

        $this->google()->assertOk()->assertJsonPath('user.email_verified', true)->assertJsonPath('user.has_password', false);

        $account = User::where('email', 'victim@example.com')->sole();
        $this->assertSame('google-victim', $account->google_id);
        $this->assertNull($account->password);
        $this->assertDatabaseMissing('sessions', ['id' => 's1']);
        $this->app['auth']->forgetGuards();
        $this->getJson('/api/v1/auth/me', ['Authorization' => "Bearer $stolen"])->assertUnauthorized();
        $this->postJson('/api/v1/auth/token', ['email' => 'victim@example.com', 'password' => 'attacker1', 'device_name' => 'x'])->assertStatus(422);
    }

    public function test_a_confirmed_account_is_linked_and_keeps_its_password(): void
    {
        $user = new User(['name' => 'Victim', 'email' => 'victim@example.com', 'password' => 'mine12345']);
        $user->email_verified_at = now();
        $user->save();
        $this->google()->assertOk()->assertJsonPath('user.id', $user->id)->assertJsonPath('user.has_password', true)->assertJsonPath('user.google', true);
        $this->google()->assertOk()->assertJsonPath('user.id', $user->id);
        $this->assertSame(1, User::count());
    }

    public function test_an_email_google_has_not_verified_is_never_linked(): void
    {
        $user = User::create(['name' => 'Someone', 'email' => 'victim@example.com', 'password' => 'mine12345']);
        $this->google(['email_verified' => false])->assertStatus(422)->assertJsonPath('errors.google.0', 'بريدك في جوجل غير مؤكد، أكّده عند جوجل أولاً.');
        $this->assertNull($user->fresh()->google_id);
        $this->assertNotNull($user->fresh()->password);
    }

    public function test_a_new_google_user_gets_a_confirmed_account_without_a_password(): void
    {
        $this->google(['sub' => 'new-1', 'email' => 'New@Example.com', 'name' => 'نور'])->assertOk()
            ->assertJsonPath('user.email', 'new@example.com')->assertJsonPath('user.name', 'نور')
            ->assertJsonPath('user.email_verified', true)->assertJsonStructure(['token', 'expires_at']);
    }

    public function test_tokens_for_another_app_expired_or_from_another_issuer_are_refused(): void
    {
        $this->google(['aud' => 'someone-elses-app'])->assertStatus(422)->assertJsonPath('errors.id_token.0', 'تعذر التحقق من حساب جوجل. حاول مجدداً.');
        $this->google(['exp' => time() - 600])->assertStatus(422);
        $this->google(['iss' => 'https://evil.example.com'])->assertStatus(422);
        $this->postJson('/api/v1/auth/google/token', ['id_token' => 'not-a-token', 'device_name' => 'x'])->assertStatus(422);
        $this->assertSame(0, User::count());
    }

    public function test_the_web_flow_uses_the_same_rules(): void
    {
        $this->expectException(ValidationException::class);
        app(GoogleLinker::class)->resolve(new GoogleIdentity('x', 'a@example.com', false, 'A'));
    }

    public function test_without_a_google_project_the_web_button_says_so(): void
    {
        config(['services.google.client_id' => null]);
        $this->get('/auth/google/redirect')->assertRedirect(config('app.frontend_url').'/login?google=off');
    }
}
