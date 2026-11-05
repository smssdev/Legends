<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\AccountCodeNotice;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Notifications\AnonymousNotifiable;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

/** [Sprint 21 E2] The five-digit account number, the code by email, the invite gift and the developers' fixed names. */
class AccountCodeTest extends TestCase
{
    use RefreshDatabase;

    private function sentCode(string $email): string
    {
        $code = null;
        Notification::assertSentTo(new AnonymousNotifiable, AccountCodeNotice::class, function ($n, $channels, $to) use ($email, &$code) {
            if ($to->routes['mail'] !== $email) {
                return false;
            }
            $html = $n->toMail($to)->render();
            preg_match('/letter-spacing:10px;[^>]*>(\d{6})</', $html, $m);
            $code = $m[1] ?? null;

            return true;
        });

        return (string) $code;
    }

    /** [X99] Wrong tries sent at once all count: once they reach the limit, even the right code is dead. */
    public function test_a_code_whose_tries_are_spent_is_dead_even_before_it_is_ended(): void
    {
        Notification::fake();
        $coach = User::factory()->create(['email' => null, 'email_verified_at' => null]);
        $this->actingAs($coach)->postJson('/api/v1/auth/verify-account/send', ['email' => 'karim@gmail.com'])->assertOk();
        $code = $this->sentCode('karim@gmail.com');
        // Parallel wrong tries counted to the limit, the code's end not written yet.
        DB::table('account_codes')->where('user_id', $coach->id)->update(['attempts' => (int) config('game.account.verify_code_attempts')]);
        $this->postJson('/api/v1/auth/verify-account', ['code' => $code])->assertStatus(422)
            ->assertJsonPath('errors.code.0', 'انتهت مدة الكود. اضغط «أرسل الكود» لكود جديد.');
        $this->assertNull($coach->fresh()->account_verified_at);
        // One wrong try short of the limit: it is counted once and ends the code.
        DB::table('account_codes')->where('user_id', $coach->id)->update(['attempts' => (int) config('game.account.verify_code_attempts') - 1]);
        $this->postJson('/api/v1/auth/verify-account', ['code' => $code === '000000' ? '111111' : '000000'])->assertStatus(422)
            ->assertJsonPath('errors.code.0', 'الكود غير صحيح، وانتهى بعد المحاولات المسموحة. اطلب كوداً جديداً.');
        $this->assertSame((int) config('game.account.verify_code_attempts'), (int) DB::table('account_codes')->where('user_id', $coach->id)->value('attempts'));
    }

    public function test_every_account_has_its_own_five_digit_number(): void
    {
        $users = User::factory()->count(30)->create();
        $numbers = $users->pluck('account_no');
        $this->assertCount(30, $numbers->unique());
        $numbers->each(fn ($n) => $this->assertTrue($n >= 10000 && $n <= 99999));
        $this->actingAs($users[0])->getJson('/api/v1/auth/me')->assertJsonPath('user.account_no', $users[0]->account_no);
    }

    public function test_the_code_comes_by_email_works_once_and_dies_after_five_wrong_tries_or_its_time(): void
    {
        Notification::fake();
        // Three sends a quarter-hour is the route's limit; this test sends more to try each case.
        $this->withoutMiddleware(ThrottleRequests::class);
        Carbon::setTestNow('2026-10-28 10:00:00');
        $coach = User::factory()->create(['email' => null, 'email_verified_at' => null]);
        $this->actingAs($coach);
        // Without an email on the account, one is needed; and not one another account has.
        User::factory()->create(['email' => 'taken@gmail.com']);
        $this->postJson('/api/v1/auth/verify-account/send')->assertStatus(422)->assertJsonValidationErrors('email');
        $this->postJson('/api/v1/auth/verify-account/send', ['email' => 'taken@gmail.com'])->assertStatus(422);
        $this->postJson('/api/v1/auth/verify-account/send', ['email' => 'Karim@Gmail.com'])->assertOk()
            ->assertJsonPath('sent', true)->assertJsonPath('email', 'k••••@gmail.com')->assertJsonPath('minutes', 15);
        $code = $this->sentCode('karim@gmail.com');
        $this->assertMatchesRegularExpression('/^\d{6}$/', $code);

        // Four wrong tries are told apart from the fifth, which ends the code.
        foreach (range(1, 4) as $i) {
            $this->postJson('/api/v1/auth/verify-account', ['code' => $code === '000000' ? '111111' : '000000'])->assertStatus(422)->assertJsonPath('errors.code.0', 'الكود غير صحيح.');
        }
        $this->postJson('/api/v1/auth/verify-account', ['code' => $code === '000000' ? '111111' : '000000'])->assertStatus(422)
            ->assertJsonPath('errors.code.0', 'الكود غير صحيح، وانتهى بعد المحاولات المسموحة. اطلب كوداً جديداً.');
        $this->postJson('/api/v1/auth/verify-account', ['code' => $code])->assertStatus(422);

        // A new code lasts 15 minutes.
        Notification::fake();
        $this->postJson('/api/v1/auth/verify-account/send', ['email' => 'karim@gmail.com'])->assertOk();
        $code = $this->sentCode('karim@gmail.com');
        Carbon::setTestNow('2026-10-28 10:16:00');
        $this->postJson('/api/v1/auth/verify-account', ['code' => $code])->assertStatus(422)->assertJsonPath('errors.code.0', 'انتهت مدة الكود. اضغط «أرسل الكود» لكود جديد.');

        // The right code in time: verified, the email kept and confirmed, the welcome coins once.
        Notification::fake();
        $this->postJson('/api/v1/auth/verify-account/send', ['email' => 'karim@gmail.com'])->assertOk();
        $code = $this->sentCode('karim@gmail.com');
        $this->postJson('/api/v1/auth/verify-account', ['code' => $code])->assertOk()->assertJsonPath('user.verification.verified', true)
            ->assertJsonPath('user.email', 'karim@gmail.com')->assertJsonPath('user.email_verified', true);
        $this->postJson('/api/v1/auth/verify-account', ['code' => $code])->assertConflict();
        $this->postJson('/api/v1/auth/verify-account/send')->assertConflict();
        $this->assertSame(1000, Wallet::balance($coach->id));
        Carbon::setTestNow();
    }

    public function test_the_email_is_designed_in_both_languages(): void
    {
        $coach = User::factory()->create(['name' => 'كريم', 'username' => 'karim']);
        $html = (new AccountCodeNotice($coach, '123456', 15))->toMail($coach)->render();
        $this->assertStringContainsString('dir="rtl"', $html);
        $this->assertStringContainsString('123456', $html);
        $this->assertStringContainsString('&#64;karim', $html);
        $this->assertStringContainsString((string) $coach->account_no, $html);
        $this->assertStringContainsString('صالح 15 دقيقة، ولمرة واحدة فقط.', $html);
        $coach->forceFill(['locale' => 'en'])->save();
        $mail = (new AccountCodeNotice($coach, '123456', 15))->toMail($coach);
        $this->assertSame('123456 is your Game Legend Manager code', $mail->subject);
        $this->assertStringContainsString('dir="ltr"', $mail->render());
    }

    public function test_an_invite_gives_100_coins_once_per_friend_who_verifies_and_stops_at_ten(): void
    {
        Notification::fake();
        $this->withoutMiddleware(ThrottleRequests::class);
        $inviter = User::factory()->create();
        $me = $this->actingAs($inviter)->getJson('/api/v1/auth/me')->json('user.referral');
        $this->assertStringEndsWith('/register?ref='.$inviter->account_no, $me['link']);
        $this->assertSame([100, 0, 10], [$me['coins'], $me['paid'], $me['max']]);

        foreach (range(1, 11) as $i) {
            $this->app['auth']->forgetGuards();
            $id = $this->postJson('/api/v1/auth/register', ['name' => "Friend {$i}", 'username' => "friend{$i}x", 'password' => 'secret-pass-1', 'password_confirmation' => 'secret-pass-1',
                'ref' => $inviter->account_no])->assertCreated()->json('user.id');
            $friend = User::find($id);
            $this->assertSame($inviter->id, $friend->referred_by);
            // Signing up is not enough: the gift waits for the friend's verification.
            $this->assertSame($i - 1 > 10 ? 1000 : min($i - 1, 10) * 100, Wallet::balance($inviter->id));
            $this->actingAs($friend)->postJson('/api/v1/auth/verify-account/send', ['email' => "friend{$i}@gmail.com"])->assertOk();
            $this->postJson('/api/v1/auth/verify-account', ['code' => $this->sentCode("friend{$i}@gmail.com")])->assertOk();
            $this->assertSame(min($i, 10) * 100, Wallet::balance($inviter->id));
        }
        $this->assertSame(10, DB::table('wallet_transactions')->where('user_id', $inviter->id)->where('type', 'referral')->count());
        $this->assertSame(10, DB::table('messages')->where('user_id', $inviter->id)->where('type', 'referral_reward')->count());
        $this->actingAs($inviter)->getJson('/api/v1/auth/me')->assertJsonPath('user.referral.paid', 10);

        // A number nobody has, or one's own, links nothing.
        $this->app['auth']->forgetGuards();
        $id = $this->postJson('/api/v1/auth/register', ['name' => 'Lone', 'username' => 'lonewolf', 'password' => 'secret-pass-1', 'password_confirmation' => 'secret-pass-1', 'ref' => $inviter->account_no === 99999 ? 99998 : 99999])->json('user.id');
        $this->assertNull(User::find($id)->referred_by);
    }

    public function test_sending_codes_is_limited(): void
    {
        Notification::fake();
        $this->actingAs(User::factory()->create(['email' => 'a@gmail.com']));
        foreach (range(1, 3) as $i) {
            $this->postJson('/api/v1/auth/verify-account/send')->assertOk();
        }
        $this->postJson('/api/v1/auth/verify-account/send')->assertStatus(429);
    }

    public function test_a_developers_name_is_fixed(): void
    {
        $dev = User::factory()->create();
        $dev->forceFill(['username' => 'owner-sliman', 'role' => 'admin'])->save();
        $this->actingAs($dev)->getJson('/api/v1/auth/me')->assertJsonPath('user.username', 'owner-sliman')->assertJsonPath('user.official', true);
        $this->patchJson('/api/v1/auth/me', ['username' => 'sliman'])->assertStatus(422)->assertJsonPath('errors.username.0', 'اسم حساب المطور ثابت ولا يتغير.');
        $this->patchJson('/api/v1/auth/me', ['name' => 'سليمان'])->assertOk();
        $this->assertSame('owner-sliman', $dev->fresh()->username);
    }
}
