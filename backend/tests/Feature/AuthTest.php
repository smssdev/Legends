<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\ResetPasswordNotice;
use App\Notifications\VerifyEmailNotice;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Notification;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    /** Requests from the web app: Sanctum gives them a session. */
    private function web(): static
    {
        return $this->withHeaders(['Origin' => 'http://localhost:5173', 'Referer' => 'http://localhost:5173/']);
    }

    private function user(array $attrs = []): User
    {
        $u = new User(array_merge(['name' => 'سليمان', 'email' => 'sliman@example.com', 'password' => 'secret123'], $attrs));
        $u->email_verified_at = $attrs['email_verified_at'] ?? now();
        $u->save();

        return $u;
    }

    public function test_register_signs_in_on_the_web_and_sends_the_arabic_confirmation(): void
    {
        Notification::fake();
        $this->web()->postJson('/api/v1/auth/register', ['name' => 'حمزة', 'username' => 'Hamza', 'email' => ' Hamza@Example.com ', 'password' => 'secret123', 'password_confirmation' => 'secret123', 'terms' => true])
            ->assertCreated()->assertJsonPath('user.email', 'hamza@example.com')->assertJsonPath('user.username', 'hamza')->assertJsonPath('user.email_verified', false)
            ->assertJsonMissingPath('token');
        $user = User::where('email', 'hamza@example.com')->firstOrFail();
        $this->assertAuthenticatedAs($user, 'web');
        Notification::assertSentTo($user, VerifyEmailNotice::class, function ($n) use ($user) {
            $mail = $n->toMail($user);

            return $mail->subject === 'أكّد بريدك في GLM' && str_contains($mail->actionUrl, '/email/verify/'.$user->id.'/');
        });
        $this->assertSame(1, DB::table('user_activity')->where('user_id', $user->id)->value('logins'));
    }

    public function test_register_refuses_in_arabic_a_weak_password_a_taken_email_and_no_terms(): void
    {
        $this->user();
        $this->postJson('/api/v1/auth/register', ['name' => 'س', 'username' => 'sliman', 'email' => 'sliman@example.com', 'password' => 'abcdefgh', 'password_confirmation' => 'abcdefgh'])
            ->assertStatus(422)->assertJsonPath('code', 'validation')
            ->assertJsonPath('errors.username.0', 'اسم المستخدم مأخوذ، اختر غيره.')
            ->assertJsonPath('errors.email.0', 'البريد الإلكتروني مستخدم من قبل.')
            ->assertJsonPath('errors.name.0', 'يجب ألا يقل الاسم عن 2 أحرف.')
            ->assertJsonPath('errors.password.0', 'يجب أن تحتوي كلمة المرور رقماً واحداً على الأقل.')
            ->assertJsonPath('errors.terms.0', 'يجب قبول الشروط.');
    }

    public function test_the_username_is_english_letters_and_digits_and_the_password_is_confirmed(): void
    {
        foreach (['ab', '1hamza', 'حمزة', 'ham_za', 'ham za', 'Owner-Hamza', str_repeat('a', 21)] as $i => $bad) {
            $this->postJson('/api/v1/auth/register', ['name' => 'حمزة', 'username' => $bad, 'email' => "h{$i}@example.com", 'password' => 'secret123', 'password_confirmation' => 'secret123', 'terms' => true])
                ->assertStatus(422)->assertJsonPath('errors.username.0', 'اسم المستخدم حروف إنجليزية وأرقام، من 3 إلى 20، ويبدأ بحرف.');
        }
        $this->postJson('/api/v1/auth/register', ['name' => 'حمزة', 'username' => 'hamza', 'email' => 'h@example.com', 'password' => 'secret123', 'password_confirmation' => 'secret124', 'terms' => true])
            ->assertStatus(422)->assertJsonPath('errors.password.0', 'تأكيد كلمة المرور غير مطابق.');
        // A taken one, whatever its case.
        $this->user(['username' => 'sliman']);
        $this->postJson('/api/v1/auth/register', ['name' => 'حمزة', 'username' => 'SLIMAN', 'email' => 'h9@example.com', 'password' => 'secret123', 'password_confirmation' => 'secret123', 'terms' => true])
            ->assertStatus(422)->assertJsonPath('errors.username.0', 'اسم المستخدم مأخوذ، اختر غيره.');
    }

    public function test_an_account_made_without_a_username_gets_a_free_one_and_can_change_it(): void
    {
        $a = $this->user(['email' => 'mo.salah@example.com']);
        $b = $this->user(['email' => 'mosalah@example.com']);
        $this->assertSame('mosalah', $a->username);
        $this->assertSame('mosalaha', $b->username);
        Sanctum::actingAs($b);
        $this->patchJson('/api/v1/auth/me', ['username' => 'MoSalah'])->assertStatus(422);
        $this->patchJson('/api/v1/auth/me', ['username' => 'Pharaoh'])->assertOk()->assertJsonPath('user.username', 'pharaoh')->assertJsonPath('user.name', 'سليمان');
    }

    public function test_the_web_signs_in_with_the_username_too(): void
    {
        $this->user(['username' => 'sliman']);
        $this->web()->postJson('/api/v1/auth/login', ['email' => 'Sliman', 'password' => 'secret123'])->assertOk()->assertJsonPath('user.username', 'sliman');
    }

    public function test_the_picture_is_cut_square_kept_small_and_shown_to_anyone(): void
    {
        $user = $this->user();
        Sanctum::actingAs($user);
        $this->postJson('/api/v1/auth/avatar', ['image' => UploadedFile::fake()->createWithContent('a.txt', 'not an image')])->assertStatus(422);
        $url = $this->post('/api/v1/auth/avatar', ['image' => UploadedFile::fake()->image('me.png', 600, 400)], ['Accept' => 'application/json'])
            ->assertOk()->json('user.avatar_url');
        $this->assertStringStartsWith("/api/v1/users/{$user->id}/avatar?v=", $url);
        $jpeg = $this->get($url)->assertOk()->assertHeader('Content-Type', 'image/jpeg')->getContent();
        $this->assertSame([256, 256], array_slice(getimagesizefromstring($jpeg), 0, 2));
        $this->deleteJson('/api/v1/auth/avatar')->assertOk()->assertJsonPath('user.avatar_url', null);
        $this->get("/api/v1/users/{$user->id}/avatar")->assertNotFound();
    }

    public function test_the_app_registers_and_gets_a_token(): void
    {
        Notification::fake();
        $this->postJson('/api/v1/auth/register', ['name' => 'حمزة', 'username' => 'hamza', 'email' => 'h@example.com', 'password' => 'secret123', 'password_confirmation' => 'secret123', 'terms' => true, 'device_name' => 'Pixel'])
            ->assertCreated()->assertJsonStructure(['token', 'expires_at']);
    }

    public function test_the_email_link_confirms_the_email_and_a_tampered_one_does_not(): void
    {
        $user = $this->user(['email_verified_at' => null]);
        $user->email_verified_at = null;
        $user->save();
        $url = VerifyEmailNotice::url($user);

        $this->get($url.'x')->assertForbidden();
        $this->assertFalse($user->fresh()->hasVerifiedEmail());

        $this->get($url)->assertRedirect(config('app.frontend_url').'/profile?verified=1');
        $this->assertTrue($user->fresh()->hasVerifiedEmail());
    }

    public function test_web_login_logout_and_a_wrong_password(): void
    {
        $user = $this->user();
        $this->web()->postJson('/api/v1/auth/login', ['email' => 'sliman@example.com', 'password' => 'wrong'])
            ->assertStatus(422)->assertJsonPath('errors.email.0', 'البريد أو كلمة المرور غير صحيحة.');
        $this->assertGuest('web');

        $this->web()->postJson('/api/v1/auth/login', ['email' => 'Sliman@example.com', 'password' => 'secret123'])
            ->assertOk()->assertJsonPath('user.name', 'سليمان')->assertJsonMissingPath('user.password');
        $this->assertAuthenticatedAs($user, 'web');

        $this->web()->postJson('/api/v1/auth/logout')->assertOk();
        $this->assertGuest('web');
    }

    public function test_the_app_cannot_use_the_session_login(): void
    {
        $this->user();
        $this->postJson('/api/v1/auth/login', ['email' => 'sliman@example.com', 'password' => 'secret123'])
            ->assertStatus(400)->assertJsonPath('code', 'bad_request');
    }

    public function test_app_token_expires_and_can_be_revoked(): void
    {
        $this->user();
        Carbon::setTestNow('2026-10-21 10:00:00');
        $res = $this->postJson('/api/v1/auth/token', ['email' => 'sliman@example.com', 'password' => 'secret123', 'device_name' => 'Pixel'])
            ->assertOk()->assertJsonPath('expires_at', '2026-11-20T10:00:00Z')->json();
        $auth = ['Authorization' => 'Bearer '.$res['token']];
        $this->getJson('/api/v1/auth/me', $auth)->assertOk()->assertJsonPath('user.email', 'sliman@example.com');

        Carbon::setTestNow('2026-11-20 10:00:01');
        $this->app['auth']->forgetGuards();
        $this->getJson('/api/v1/auth/me', $auth)->assertUnauthorized()->assertJsonPath('message', 'سجّل الدخول أولاً.');

        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->app['auth']->forgetGuards();
        $this->deleteJson('/api/v1/auth/token', [], $auth)->assertOk();
        $this->app['auth']->forgetGuards();
        $this->getJson('/api/v1/auth/me', $auth)->assertUnauthorized();
        Carbon::setTestNow();
    }

    public function test_too_many_attempts_get_the_arabic_rate_limit(): void
    {
        $this->user();
        for ($i = 0; $i < 5; $i++) {
            $this->postJson('/api/v1/auth/token', ['email' => 'sliman@example.com', 'password' => 'wrong', 'device_name' => 'x'])->assertStatus(422);
        }
        $this->postJson('/api/v1/auth/token', ['email' => 'sliman@example.com', 'password' => 'secret123', 'device_name' => 'x'])
            ->assertStatus(429)->assertJsonPath('message', 'طلبات كثيرة، حاول بعد قليل.');
    }

    public function test_forgot_password_tells_nobody_which_emails_exist_and_reset_signs_out_everywhere(): void
    {
        Notification::fake();
        $user = $this->user(['email_verified_at' => null]);
        $user->email_verified_at = null;
        $user->save();
        $old = $user->createToken('old')->plainTextToken;

        $unknown = $this->postJson('/api/v1/auth/forgot-password', ['email' => 'nobody@example.com'])->assertStatus(202)->json('message');
        $known = $this->postJson('/api/v1/auth/forgot-password', ['email' => 'sliman@example.com'])->assertStatus(202)->json('message');
        $this->assertSame($unknown, $known);

        $token = null;
        Notification::assertSentTo($user, ResetPasswordNotice::class, function ($n) use (&$token, $user) {
            $token = $n->token;

            return str_starts_with($n->url($user), config('app.frontend_url').'/reset-password?token=');
        });

        $this->postJson('/api/v1/auth/reset-password', ['token' => 'bad', 'email' => 'sliman@example.com', 'password' => 'newpass123'])
            ->assertStatus(422)->assertJsonPath('errors.email.0', 'الرابط منتهي أو غير صحيح. اطلب رابطاً جديداً.');
        $this->postJson('/api/v1/auth/reset-password', ['token' => $token, 'email' => 'sliman@example.com', 'password' => 'newpass123'])->assertOk();

        $this->app['auth']->forgetGuards();
        $this->getJson('/api/v1/auth/me', ['Authorization' => "Bearer $old"])->assertUnauthorized();
        $this->postJson('/api/v1/auth/token', ['email' => 'sliman@example.com', 'password' => 'newpass123', 'device_name' => 'x'])->assertOk();
        $this->assertTrue($user->fresh()->hasVerifiedEmail());
    }

    public function test_profile_name_and_password_change(): void
    {
        $user = $this->user();
        Sanctum::actingAs($user);
        $this->patchJson('/api/v1/auth/me', ['name' => 'كوتش سليمان'])->assertOk()->assertJsonPath('user.name', 'كوتش سليمان');
        $this->putJson('/api/v1/auth/password', ['current_password' => 'nope', 'password' => 'another123'])
            ->assertStatus(422)->assertJsonPath('errors.current_password.0', 'كلمة المرور الحالية غير صحيحة.');
        $this->putJson('/api/v1/auth/password', ['current_password' => 'secret123', 'password' => 'another123'])->assertOk();
        $this->assertTrue(password_verify('another123', $user->fresh()->password));
    }

    public function test_resend_confirmation_only_while_unconfirmed(): void
    {
        Notification::fake();
        $user = $this->user();
        Sanctum::actingAs($user);
        $this->postJson('/api/v1/auth/email/resend')->assertStatus(409)->assertJsonPath('message', 'بريدك مؤكد من قبل.');
        $user->email_verified_at = null;
        $user->save();
        $this->postJson('/api/v1/auth/email/resend')->assertStatus(202);
        Notification::assertSentTo($user, VerifyEmailNotice::class);
    }

    public function test_delete_account_needs_the_password_and_removes_everything(): void
    {
        $user = $this->user();
        $user->createToken('phone');
        Sanctum::actingAs($user);
        // Asked twice [X12]: without the word, nothing goes, whatever the password.
        $this->deleteJson('/api/v1/auth/me', ['password' => 'secret123'])->assertStatus(422)->assertJsonPath('errors.phrase.0', 'اكتب كلمة «احذف» للتأكيد.');
        $this->deleteJson('/api/v1/auth/me', ['password' => 'secret123', 'phrase' => 'نعم'])->assertStatus(422)->assertJsonPath('errors.phrase.0', 'اكتب كلمة «احذف» كما هي.');
        $this->deleteJson('/api/v1/auth/me', ['password' => 'wrong', 'phrase' => 'احذف'])->assertStatus(422)->assertJsonPath('errors.password.0', 'كلمة المرور غير صحيحة.');
        $this->deleteJson('/api/v1/auth/me', ['password' => 'secret123', 'phrase' => 'احذف'])->assertOk()->assertJsonPath('deleted', true);
        $this->assertDatabaseMissing('users', ['id' => $user->id]);
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_a_google_only_account_confirms_deletion_with_its_email(): void
    {
        $user = $this->user(['password' => null, 'google_id' => 'g-1']);
        Sanctum::actingAs($user);
        $this->deleteJson('/api/v1/auth/me', ['confirm' => 'other@example.com', 'phrase' => 'احذف'])->assertStatus(422);
        $this->deleteJson('/api/v1/auth/me', ['confirm' => 'SLIMAN@example.com', 'phrase' => 'احذف'])->assertOk();
        $this->assertDatabaseMissing('users', ['id' => $user->id]);
    }

    public function test_outside_development_the_simulator_is_for_admins_only(): void
    {
        config(['game.simulator.enabled' => false]);
        $this->getJson('/api/v1/sim/leagues')->assertNotFound();
        Sanctum::actingAs($this->user());
        $this->getJson('/api/v1/sim/leagues')->assertNotFound();
        $admin = $this->user(['email' => 'admin@example.com']);
        $admin->role = 'admin';
        $admin->save();
        Sanctum::actingAs($admin);
        $this->getJson('/api/v1/sim/leagues')->assertOk();
    }
}
