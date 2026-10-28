<?php

namespace App\Auth;

use App\Messages\Inbox;
use App\Models\User;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Support\Facades\DB;

/**
 * The invite gift [Sprint 21 E2.3, the owner's decision 2026-10-28]: every account has a link with its account
 * number (/register?ref=12345). A coach who signs up from it and verifies their account gives the inviter
 * game.account.referral_coins, once per invited account and up to game.account.referral_max gifts per inviter.
 */
class Referral
{
    /** The new account remembers who invited it; a wrong or unknown number is simply ignored. */
    public static function link(User $user, ?int $accountNo): void
    {
        if (! $accountNo) {
            return;
        }
        $by = User::where('account_no', $accountNo)->value('id');
        if ($by && $by !== $user->id) {
            $user->forceFill(['referred_by' => $by])->save();
        }
    }

    /** How many gifts this account has had. */
    public static function paid(int $userId): int
    {
        return DB::table('users')->where('referred_by', $userId)->whereNotNull('referral_paid_at')->count();
    }

    /** The verified account's inviter gets the gift, once, while under the cap. */
    public static function reward(User $user): bool
    {
        if (! $user->referred_by || $user->referral_paid_at !== null || $user->account_verified_at === null) {
            return false;
        }
        $inviter = (int) $user->referred_by;
        $coins = (int) config('game.account.referral_coins');
        $paid = DB::transaction(function () use ($user, $inviter, $coins) {
            if (self::paid($inviter) >= (int) config('game.account.referral_max')) {
                return false;
            }
            // Marked first, by a conditional update: a second request finds it taken.
            if (DB::table('users')->where('id', $user->id)->whereNull('referral_paid_at')->update(['referral_paid_at' => GameClock::now()]) !== 1) {
                return false;
            }
            Wallet::post($inviter, 'referral', $coins, 'referral:'.$user->id, 'user:'.$user->id);

            return true;
        });
        if ($paid) {
            Inbox::send($inviter, 'referral_reward', ['coins' => $coins, 'name' => $user->name, 'left' => max(0, (int) config('game.account.referral_max') - self::paid($inviter))]);
        }

        return $paid;
    }

    /** What the account page shows: the link, the gifts so far and the cap. */
    public static function summary(User $user): array
    {
        $max = (int) config('game.account.referral_max');

        return ['link' => rtrim((string) config('app.url'), '/').'/register?ref='.$user->account_no, 'coins' => (int) config('game.account.referral_coins'),
            'paid' => self::paid($user->id), 'max' => $max,
            'waiting' => DB::table('users')->where('referred_by', $user->id)->whereNull('referral_paid_at')->count()];
    }
}
