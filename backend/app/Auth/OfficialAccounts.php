<?php

namespace App\Auth;

use App\Models\User;
use Illuminate\Support\Facades\Log;

/**
 * The developers' two fixed accounts [X11]: each reserved name (Owner-Hamza, Owner-Soliman) belongs to one Gmail,
 * set on the server only (OWNER_HAMZA_EMAIL, OWNER_SOLIMAN_EMAIL), never in the code. Whoever signs in with that
 * address, once it is confirmed (the email's link, or Google), gets the name, the official badge and the admin
 * panel. An unconfirmed address gets nothing: anyone may type an email.
 */
class OfficialAccounts
{
    /** The reserved name for this email, or null. */
    public static function nameFor(?string $email): ?string
    {
        $email = strtolower(trim((string) $email));
        if ($email === '') {
            return null;
        }
        foreach (config('game.account.official_emails') as $name => $address) {
            if ($address && strtolower(trim($address)) === $email) {
                return $name;
            }
        }

        return null;
    }

    /** Give the account its reserved name and the admin role when its confirmed email is a developer's. */
    public static function claim(User $user): bool
    {
        $name = self::nameFor($user->email);
        if (! $name || ! $user->hasVerifiedEmail()) {
            return false;
        }
        $lower = strtolower($name);
        if ($user->username === $lower && $user->role === 'admin') {
            return false;
        }
        // The name was given by hand to another account before: it comes back to its owner.
        User::where('username', $lower)->where('id', '!=', $user->id)->get()
            ->each(fn (User $other) => $other->forceFill(['username' => Username::free($other->name.' '.strtok((string) $other->email, '@'))])->save());
        $user->forceFill(['username' => $lower, 'role' => 'admin'])->save();
        Log::info("Official account: {$name} is user {$user->id}");

        return true;
    }
}
