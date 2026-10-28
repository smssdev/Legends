<?php

namespace App\Auth;

use App\Models\User;
use App\Notifications\AccountCodeNotice;
use App\Support\GameClock;
use App\Support\Mailer;
use App\Wallet\Wallet;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Illuminate\Validation\ValidationException;

/**
 * Verifying an account [UP6; by email since Sprint 21 E2.4, the owner's decision 2026-10-28]. "Send the code" mails a
 * six-digit code to the coach's address from the game's Gmail; it is valid game.account.verify_code_minutes, once,
 * and game.account.verify_code_attempts wrong tries end it. The right code verifies the account (and its email),
 * the welcome coins (game.account.welcome_coins) reach the wallet once, and the inviter gets their gift (Referral).
 * A developer can still issue a code from the admin panel for a coach who cannot receive email.
 */
class AccountVerification
{
    /** A new six-digit code for this account, kept hashed; it replaces any earlier one. */
    public static function issue(User $user, ?User $by = null): string
    {
        abort_if($user->account_verified_at !== null, 409, 'هذا الحساب موثّق من قبل.');
        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $now = GameClock::now();
        DB::transaction(function () use ($user, $by, $code, $now) {
            DB::table('account_codes')->where('user_id', $user->id)->whereNull('used_at')->update(['expires_at' => $now, 'updated_at' => $now]);
            DB::table('account_codes')->insert(['user_id' => $user->id, 'code_hash' => Hash::make($code), 'created_by' => $by?->id,
                'expires_at' => $now->copy()->addDays((int) config('game.account.verify_code_days')), 'created_at' => $now, 'updated_at' => $now]);
        });

        return $code;
    }

    /** [Sprint 21 E2.4] A fresh code mailed to this address (kept with the code; the account takes it once verified). */
    public static function send(User $user, string $email): bool
    {
        abort_if($user->account_verified_at !== null, 409, 'حسابك موثّق من قبل.');
        $code = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $now = GameClock::now();
        $minutes = (int) config('game.account.verify_code_minutes');
        DB::transaction(function () use ($user, $code, $now, $email, $minutes) {
            DB::table('account_codes')->where('user_id', $user->id)->whereNull('used_at')->update(['expires_at' => $now, 'updated_at' => $now]);
            DB::table('account_codes')->insert(['user_id' => $user->id, 'code_hash' => Hash::make($code), 'email' => $email,
                'expires_at' => $now->copy()->addMinutes($minutes), 'created_at' => $now, 'updated_at' => $now]);
        });

        return Mailer::attempt(fn () => Notification::route('mail', $email)->notify(new AccountCodeNotice($user, $code, $minutes)), 'code '.$user->id);
    }

    /** a••••@gmail.com: enough for the coach to know where to look, not enough to read someone's address. */
    public static function masked(string $email): string
    {
        [$name, $domain] = array_pad(explode('@', $email, 2), 2, '');

        return mb_substr($name, 0, 1).str_repeat('•', max(2, min(6, mb_strlen($name) - 1))).'@'.$domain;
    }

    /** The coach's code: right and in time, the account is verified and the welcome coins arrive. */
    public static function verify(User $user, string $code): User
    {
        abort_if($user->account_verified_at !== null, 409, 'حسابك موثّق من قبل.');
        $now = GameClock::now();
        $row = DB::table('account_codes')->where('user_id', $user->id)->whereNull('used_at')->where('expires_at', '>', $now)->orderByDesc('id')->first();
        if (! $row) {
            throw ValidationException::withMessages(['code' => 'انتهت مدة الكود. اضغط «أرسل الكود» لكود جديد.']);
        }
        if (! Hash::check(trim($code), $row->code_hash)) {
            // Each wrong try counts; the last one ends the code, so it cannot be guessed.
            $tries = (int) $row->attempts + 1;
            $last = $tries >= (int) config('game.account.verify_code_attempts');
            DB::table('account_codes')->where('id', $row->id)->update(['attempts' => $tries, 'updated_at' => $now] + ($last ? ['expires_at' => $now] : []));
            throw ValidationException::withMessages(['code' => $last ? 'الكود غير صحيح، وانتهى بعد المحاولات المسموحة. اطلب كوداً جديداً.' : 'الكود غير صحيح.']);
        }
        DB::transaction(function () use ($user, $row, $now) {
            // One use: the conditional update decides, whichever request comes first.
            if (DB::table('account_codes')->where('id', $row->id)->whereNull('used_at')->update(['used_at' => $now, 'updated_at' => $now]) !== 1) {
                throw ValidationException::withMessages(['code' => 'استُعمل هذا الكود من قبل.']);
            }
            // A code that came by email proves the address: the account keeps it, confirmed.
            $email = $row->email && ! DB::table('users')->where('email', $row->email)->where('id', '!=', $user->id)->exists() ? $row->email : null;
            DB::table('users')->where('id', $user->id)->whereNull('account_verified_at')->update(['account_verified_at' => $now]
                + ($email ? ['email' => $email, 'email_verified_at' => $now] : []));
            Wallet::post($user->id, 'welcome', (int) config('game.account.welcome_coins'), 'welcome:'.$user->id, 'account verified');
        });
        $user->refresh();
        Referral::reward($user);
        // A developer's confirmed Gmail takes its reserved name [X11].
        OfficialAccounts::claim($user);

        return $user;
    }
}
