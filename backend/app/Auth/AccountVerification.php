<?php

namespace App\Auth;

use App\Models\User;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

/**
 * Verifying an account by WhatsApp [UP6, the owner's spec 1, 2026-10-26]. The coach writes to the support with a
 * ready message (their username and account number), a developer issues a code from the admin panel and sends it
 * back, and the coach types it in their account. Only then do the welcome coins (game.account.welcome_coins) reach
 * the wallet, once. Making the codes by themselves comes later (the spec's own note).
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

    /** The coach's code: right and in time, the account is verified and the welcome coins arrive. */
    public static function verify(User $user, string $code): User
    {
        abort_if($user->account_verified_at !== null, 409, 'حسابك موثّق من قبل.');
        $now = GameClock::now();
        $row = DB::table('account_codes')->where('user_id', $user->id)->whereNull('used_at')->where('expires_at', '>', $now)->orderByDesc('id')->first();
        if (! $row || ! Hash::check(trim($code), $row->code_hash)) {
            throw ValidationException::withMessages(['code' => 'الكود غير صحيح أو انتهت مدته. اطلب كوداً جديداً من الدعم.']);
        }
        DB::transaction(function () use ($user, $row, $now) {
            // One use: the conditional update decides, whichever request comes first.
            if (DB::table('account_codes')->where('id', $row->id)->whereNull('used_at')->update(['used_at' => $now, 'updated_at' => $now]) !== 1) {
                throw ValidationException::withMessages(['code' => 'استُعمل هذا الكود من قبل.']);
            }
            DB::table('users')->where('id', $user->id)->whereNull('account_verified_at')->update(['account_verified_at' => $now]);
            Wallet::post($user->id, 'welcome', (int) config('game.account.welcome_coins'), 'welcome:'.$user->id, 'account verified');
        });

        return $user->refresh();
    }

    /** The ready WhatsApp message to the support: the username and the account's number. */
    public static function whatsappLink(User $user): ?string
    {
        $number = preg_replace('/\D+/', '', (string) config('game.support.whatsapp'));
        if ($number === '') {
            return null;
        }
        $text = "مرحباً، أريد توثيق حسابي في لعبة المدرب الأسطورة.\nاسم المستخدم: {$user->username}\nرقم الحساب: {$user->id}";

        return 'https://wa.me/'.$number.'?text='.rawurlencode($text);
    }
}
