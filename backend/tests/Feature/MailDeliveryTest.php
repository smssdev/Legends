<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Mail;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/** [X8] The confirmation email over HTTPS (Render blocks SMTP), and no lost sign-up when it cannot leave. */
class MailDeliveryTest extends TestCase
{
    use RefreshDatabase;

    private function signUp(): TestResponse
    {
        return $this->postJson('/api/v1/auth/register', ['name' => 'حمزة', 'username' => 'hamza', 'email' => 'h@example.com',
            'password' => 'secret123', 'password_confirmation' => 'secret123', 'terms' => true, 'device_name' => 'Pixel']);
    }

    public function test_brevo_receives_the_arabic_confirmation_with_its_link(): void
    {
        config(['mail.default' => 'brevo', 'mail.mailers.brevo.key' => 'test-key', 'mail.from.address' => 'legends@gmail.com']);
        Http::fake(['api.brevo.com/*' => Http::response(['messageId' => 'x'], 201)]);

        $this->signUp()->assertCreated()->assertJsonPath('verification_sent', true);

        Http::assertSent(function (Request $r) {
            return $r->url() === 'https://api.brevo.com/v3/smtp/email' && $r->hasHeader('api-key', 'test-key')
                && $r['sender']['email'] === 'legends@gmail.com' && $r['to'][0]['email'] === 'h@example.com'
                && $r['subject'] === 'أكّد بريدك في الأساطير' && str_contains($r['htmlContent'], '/email/verify/');
        });
    }

    public function test_resend_receives_the_email_with_a_bearer_key(): void
    {
        config(['mail.default' => 'resend', 'mail.mailers.resend.key' => 're_key', 'mail.from.address' => 'onboarding@resend.dev']);
        Http::fake(['api.resend.com/*' => Http::response(['id' => 'x'], 200)]);

        $this->signUp()->assertCreated()->assertJsonPath('verification_sent', true);

        Http::assertSent(fn (Request $r) => $r->url() === 'https://api.resend.com/emails' && $r->hasHeader('Authorization', 'Bearer re_key')
            && $r['to'] === ['h@example.com'] && str_contains($r['html'], '/email/verify/'));
    }

    public function test_a_refused_email_keeps_the_account_and_resend_says_why(): void
    {
        config(['mail.default' => 'brevo', 'mail.mailers.brevo.key' => 'bad', 'mail.from.address' => 'legends@gmail.com']);
        Http::fake(['api.brevo.com/*' => Http::response(['message' => 'Key not found'], 401)]);

        $this->signUp()->assertCreated()->assertJsonPath('verification_sent', false)->assertJsonStructure(['token']);
        $user = User::where('email', 'h@example.com')->firstOrFail();

        Sanctum::actingAs($user);
        $this->postJson('/api/v1/auth/email/resend')->assertStatus(503)
            ->assertJsonPath('message', 'تعذر إرسال الرسالة الآن. حاول بعد دقائق، أو تواصل مع الدعم.');
    }

    public function test_in_production_a_server_without_a_mailer_says_so(): void
    {
        $user = User::factory()->unverified()->create();
        config(['mail.default' => 'log']);
        $this->app->detectEnvironment(fn () => 'production');
        Sanctum::actingAs($user);
        $this->postJson('/api/v1/auth/email/resend')->assertStatus(503)
            ->assertJsonPath('message', 'إرسال البريد غير مفعّل على الخادم بعد. تواصل مع الدعم ليفعّله.');
    }

    public function test_mail_check_prints_the_reason_it_failed(): void
    {
        config(['mail.default' => 'brevo', 'mail.mailers.brevo.key' => 'bad', 'mail.from.address' => 'legends@gmail.com']);
        Http::fake(['api.brevo.com/*' => Http::response(['message' => 'Key not found'], 401)]);
        $this->artisan('mail:check', ['to' => 'me@example.com'])->expectsOutputToContain('Key not found')->assertFailed();

        Mail::fake();
        config(['mail.default' => 'array']);
        $this->artisan('mail:check', ['to' => 'me@example.com'])->assertSuccessful();
    }
}
