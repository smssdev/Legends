<?php

namespace App\Http\Controllers;

use App\Auth\GoogleIdentity;
use App\Auth\GoogleLinker;
use App\Auth\OfficialAccounts;
use App\Models\User;
use App\Support\Activity;
use Illuminate\Auth\Events\Verified;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use Laravel\Socialite\Facades\Socialite;
use Throwable;

/**
 * The links that open in the browser, not the API: the email confirmation from the email, and
 * Google's sign-in on the web (Socialite). Each ends on a screen of the web app.
 */
class AccountLinkController extends Controller
{
    private function to(string $path): RedirectResponse
    {
        return redirect()->away(rtrim(config('app.frontend_url'), '/').$path);
    }

    public function verify(Request $request, int $id, string $hash): RedirectResponse
    {
        $user = User::find($id);
        if (! $user || ! hash_equals(sha1($user->getEmailForVerification()), $hash)) {
            return $this->to('/login?verified=invalid');
        }
        if ($user->markEmailAsVerified()) {
            event(new Verified($user));
        }
        // A developer's Gmail, now confirmed, takes its reserved name [X11].
        OfficialAccounts::claim($user);

        return $this->to('/profile?verified=1');
    }

    public function googleRedirect(): RedirectResponse
    {
        if (! config('services.google.client_id')) {
            return $this->to('/login?google=off');
        }

        return Socialite::driver('google')->redirect();
    }

    public function googleCallback(Request $request, GoogleLinker $linker): RedirectResponse
    {
        try {
            $g = Socialite::driver('google')->user();
        } catch (Throwable) {
            return $this->to('/login?google=failed');
        }
        $raw = $g->getRaw();
        $verified = ($raw['email_verified'] ?? $raw['verified_email'] ?? false) === true;
        try {
            $user = $linker->resolve(new GoogleIdentity((string) $g->getId(), strtolower((string) $g->getEmail()), $verified, (string) $g->getName(), $g->getAvatar() ?: null));
        } catch (ValidationException) {
            return $this->to('/login?google=unverified');
        }
        OfficialAccounts::claim($user);
        Auth::guard('web')->login($user, true);
        $request->session()->regenerate();
        Activity::record($user->id, 'logins');

        return $this->to('/');
    }
}
