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
    /**
     * [Sprint 50 M5] A guest keeps the account with Google: the Google account must be verified and not ours already,
     * and its email no other account's. The guest becomes the Google account, nothing lost.
     */
    public function attach(User $guest, GoogleIdentity $google): User
    {
        GuestAccounts::assertGuest($guest);
        if (! $google->emailVerified) {
            throw ValidationException::withMessages(['google' => 'بريدك في جوجل غير مؤكد، أكّده عند جوجل أولاً.']);
        }
        if (User::where('google_id', $google->sub)->orWhere('email', $google->email)->where('id', '!=', $guest->id)->exists()) {
            throw ValidationException::withMessages(['google' => 'حساب جوجل هذا له حساب في اللعبة. ادخل به، أو احفظ حسابك باسم مستخدم.']);
        }
        $guest->forceFill(['google_id' => $google->sub, 'email' => $google->email, 'guest_at' => null,
            'name' => $google->name !== '' ? mb_substr($google->name, 0, 40) : $guest->name,
            'google_picture' => $google->picture !== null && str_starts_with($google->picture, 'https://') ? substr($google->picture, 0, 500) : null,
            'email_verified_at' => $guest->email_verified_at ?? GameClock::now()])->save();

        return $guest;
    }

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
                Sessions::forget($user->id);
            }
            $user->google_id = $google->sub;
            $user->google_picture = $google->picture !== null && str_starts_with($google->picture, 'https://') ? substr($google->picture, 0, 500) : $user->google_picture;
            $user->email_verified_at ??= GameClock::now();
            $user->save();

            return $user;
        });
    }
}
