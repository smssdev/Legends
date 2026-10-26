<?php

namespace App\Auth;

use App\Models\User;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Turns a Google sign-in into one of our accounts, safely [PLAN 2.17].
 *
 * Someone could register with a victim's email and a password of their own, never confirm it,
 * and wait for the victim to arrive with Google. So:
 * - Google must say the email is verified, or nothing happens.
 * - An account whose email we confirmed is linked as it is.
 * - An account whose email we never confirmed is wiped of its sign-ins before Google takes it:
 *   its password, its app tokens and its web sessions go, so whoever made it is locked out.
 * - Otherwise a new account, already confirmed, named after the Google account: its name, its picture and a
 *   username made from the name [UP5], so the coach types nothing.
 */
class GoogleLinker
{
    public function resolve(GoogleIdentity $google): User
    {
        $user = User::where('google_id', $google->sub)->first();
        if ($user) {
            return $user;
        }
        if (! $google->emailVerified) {
            throw ValidationException::withMessages(['google' => 'بريدك في جوجل غير مؤكد، أكّده عند جوجل أولاً.']);
        }

        return DB::transaction(function () use ($google) {
            $user = User::where('email', $google->email)->first();
            if (! $user) {
                $name = $google->name !== '' ? $google->name : (string) strtok($google->email, '@');
                $user = new User(['name' => mb_substr($name, 0, 40), 'email' => $google->email, 'username' => Username::fromName($name, $google->email)]);
            } elseif (! $user->hasVerifiedEmail()) {
                $user->password = null;
                $user->setRememberToken(null);
                $user->tokens()->delete();
                DB::table('sessions')->where('user_id', $user->id)->delete();
            }
            $user->google_id = $google->sub;
            $user->google_picture = $google->picture !== null && str_starts_with($google->picture, 'https://') ? substr($google->picture, 0, 500) : $user->google_picture;
            $user->email_verified_at ??= GameClock::now();
            $user->save();

            return $user;
        });
    }
}
