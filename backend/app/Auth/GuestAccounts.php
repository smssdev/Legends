<?php

namespace App\Auth;

use App\Models\User;
use App\Support\GameClock;
use Illuminate\Support\Str;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [Sprint 50 M5] Playing as a guest: one tap makes an account with no password or email, signed in by the app's
 * token, that plays the whole game. A username and a password (or Google, through GoogleLinker) keep it, nothing
 * lost. A guest left so for game.account.guest_days is deleted as any account (AccountDeletion), its clubs back to the bots.
 */
class GuestAccounts
{
    public static function create(): User
    {
        do {
            $username = 'guest'.random_int(100000, 999999);
        } while (Username::taken($username));
        $user = new User(['name' => 'زائر '.substr($username, -4), 'username' => $username, 'email' => null, 'password' => null]);
        $user->guest_at = GameClock::now();
        $user->save();

        return $user;
    }

    /** The guest keeps the account: its own name, username and password, and an email if typed. */
    public static function keep(User $user, string $name, string $username, string $password, ?string $email): User
    {
        self::assertGuest($user);
        $user->forceFill(['name' => trim($name), 'username' => strtolower($username), 'password' => $password, 'email' => $email, 'guest_at' => null])->save();

        return $user;
    }

    public static function assertGuest(User $user): void
    {
        if ($user->guest_at === null) {
            throw new HttpException(409, __('هذا الحساب محفوظ من قبل.'));
        }
    }

    /** The guests never kept, past their days: deleted as any account. Returns how many. */
    public static function prune(): int
    {
        $before = GameClock::now()->subDays((int) config('game.account.guest_days'));
        $n = 0;
        User::whereNotNull('guest_at')->where('guest_at', '<', $before)->orderBy('id')->each(function (User $u) use (&$n) {
            AccountDeletion::delete($u);
            $n++;
        });

        return $n;
    }

    /** A guest's name, as the screens show it, never taken for a real one. */
    public static function isGuestName(string $username): bool
    {
        return Str::startsWith(strtolower($username), 'guest');
    }
}
