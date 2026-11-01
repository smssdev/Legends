<?php

namespace App\Wallet;

use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 30 P6] A new coach's first coins (game.account.starter_coins, 25), claimed once from the home screen, before
 * and apart from the verification reward: enough for the first steps (and the first friendly is free, Friendlies).
 */
class StarterGift
{
    public static function key(int $userId): string
    {
        return 'starter:'.$userId;
    }

    public static function claimed(int $userId): bool
    {
        return DB::table('wallet_transactions')->where('idempotency_key', self::key($userId))->exists();
    }

    public static function view(User $user): array
    {
        return ['coins' => (int) config('game.account.starter_coins'), 'claimed' => self::claimed($user->id)];
    }

    /** Once per account, whatever the taps: the wallet's key makes a second claim the first one. */
    public static function claim(User $user): int
    {
        return Wallet::post($user->id, 'starter', (int) config('game.account.starter_coins'), self::key($user->id), 'starter gift');
    }
}
