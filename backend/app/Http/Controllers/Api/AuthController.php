<?php

namespace App\Http\Controllers\Api;

use App\Auth\AccountDeletion;
use App\Auth\AccountHolidays;
use App\Auth\AccountVerification;
use App\Auth\GoogleLinker;
use App\Auth\GoogleTokenVerifier;
use App\Auth\GuestAccounts;
use App\Auth\OfficialAccounts;
use App\Auth\Referral;
use App\Auth\Sessions;
use App\Auth\Username;
use App\Http\Controllers\Controller;
use App\Http\Middleware\SetLocale;
use App\League\Presence;
use App\Models\User;
use App\Support\Activity;
use App\Support\Avatar;
use App\Support\GameClock;
use App\Support\Mailer;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password as PasswordRule;
use Illuminate\Validation\ValidationException;

/**
 * Accounts [PLAN 2.17]. The web signs in with a Sanctum session cookie (register, login,
 * logout); the app with a token that expires (token, google/token). Both reach the same account.
 */
class AuthController extends Controller
{
    private const WRONG = 'البريد أو كلمة المرور غير صحيحة.';

    /** [UP5] Simple and the coach's own: no symbols, no mixed case, no long minimum (the owner's spec, 1). */
    private function passwordRule(): PasswordRule
    {
        // [Sprint 30 Q11] 8 at least (game.account.password_min), the owner's report; older passwords still sign in.
        return PasswordRule::min((int) config('game.account.password_min'));
    }

    public function register(Request $request): JsonResponse
    {
        $email = Str::lower(trim((string) $request->input('email')));
        $request->merge(['email' => $email !== '' ? $email : null]);
        // [UP5] Three fields on one screen: the name, the username and the password, typed once. The email is optional
        // (to get the password back by mail); the account is verified later by WhatsApp (UP6).
        $data = $request->validate([
            'name' => ['required', 'string', 'min:2', 'max:40'],
            'username' => ['required', 'string', Username::RULE, $this->usernameFree()],
            'email' => ['nullable', 'string', 'email', 'max:190', 'unique:users,email'],
            'password' => ['required', 'string', $this->passwordRule()],
            'device_name' => ['sometimes', 'string', 'max:100'],
            // [Sprint 21 E2.3] The inviter's account number, from their invite link (?ref=12345).
            'ref' => ['sometimes', 'nullable', 'integer', 'between:10000,99999'],
        ]);
        $request->merge(['remember' => true]);
        $user = User::create(['name' => trim($data['name']), 'username' => $data['username'], 'email' => ($data['email'] ?? '') !== '' ? $data['email'] : null, 'password' => $data['password']]);
        Referral::link($user, $data['ref'] ?? null);
        // The account is made even if the email cannot leave now: the banner in the app sends it again [X8].
        $sent = $user->email !== null && Mailer::attempt(fn () => $user->sendEmailVerificationNotification(), 'verify '.$user->id);

        return response()->json($this->signIn($request, $user, $data['device_name'] ?? null) + ['verification_sent' => $sent && Mailer::live()], 201);
    }

    public function login(Request $request): JsonResponse
    {
        abort_unless($request->hasSession(), 400, 'الدخول بالجلسة للويب فقط. التطبيق يستخدم /auth/token.');
        // The email or the username [X4]. [UP5] The session lasts unless the coach asks otherwise.
        $data = $request->validate(['email' => ['required', 'string', 'max:190'], 'password' => ['required', 'string'], 'remember' => ['sometimes', 'boolean']]);
        if (! Auth::guard('web')->attempt([$this->loginField($data['email']) => Str::lower(trim($data['email'])), 'password' => $data['password']], (bool) ($data['remember'] ?? true))) {
            throw ValidationException::withMessages(['email' => self::WRONG]);
        }

        return response()->json($this->signIn($request, Auth::guard('web')->user()));
    }

    public function logout(Request $request): JsonResponse
    {
        Auth::guard('web')->logout();
        if ($request->hasSession()) {
            $request->session()->invalidate();
            $request->session()->regenerateToken();
        }

        return response()->json(['signed_out' => true]);
    }

    /**
     * [Sprint 30 Q11] A guest on the site gets 204 (nobody signed in), not a 401 the browser logs as an error. A token
     * that no longer works (the app's, expired or revoked) still gets the 401 that sends it to sign in again.
     */
    public function me(Request $request): JsonResponse|Response
    {
        $user = $request->user('sanctum');
        if (! $user && $request->bearerToken()) {
            throw new AuthenticationException;
        }

        return $user ? response()->json(['user' => $user->toAccount()]) : response()->noContent();
    }

    /** The name and the username [X4], the commentator [X9], the simulator [X10], the language [UP2] and the coach's look [Sprint 26]; any of them may be sent alone. */
    public function update(Request $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validate([
            'name' => ['required_without_all:username,commentator,match_view,locale,coach_look', 'string', 'min:2', 'max:40'],
            'username' => ['sometimes', 'string', Username::RULE, $this->usernameFree($user->id)],
            'commentator' => ['sometimes', 'string', Rule::in(config('game.viewing.commentators'))],
            'match_view' => ['sometimes', 'string', Rule::in(config('game.viewing.match_views'))],
            'locale' => ['sometimes', 'string', Rule::in(SetLocale::LOCALES)],
            'coach_look' => ['sometimes', 'string', Rule::in(config('game.characters.looks'))],
        ]);
        // [Sprint 21 E2.6] A developer's name (Owner-Sizar, Owner-Sliman) stays as it is.
        if (isset($data['username']) && Username::official($user->username) && strtolower($data['username']) !== $user->username) {
            throw ValidationException::withMessages(['username' => 'اسم حساب المطور ثابت ولا يتغير.']);
        }
        $user->update(array_filter(['name' => isset($data['name']) ? trim($data['name']) : null,
            'username' => isset($data['username']) ? strtolower($data['username']) : null,
            'commentator' => $data['commentator'] ?? null, 'match_view' => $data['match_view'] ?? null, 'locale' => $data['locale'] ?? null,
            'coach_look' => $data['coach_look'] ?? null]));

        return response()->json(['user' => $user->toAccount()]);
    }

    /** A username nobody else has, whatever its case, and not one of the staff's words [X11]. */
    private function usernameFree(?int $except = null): \Closure
    {
        return function (string $attribute, mixed $value, \Closure $fail) use ($except) {
            if (is_string($value) && ($why = Username::refusal($value, $except)) !== null) {
                $fail($why);
            }
        };
    }

    /** Is this username free? With three free ones near it when it is not [X11]. */
    public function usernameCheck(Request $request): JsonResponse
    {
        $name = (string) $request->validate(['u' => ['required', 'string', 'max:40']])['u'];
        $why = preg_match('/^[A-Za-z][A-Za-z0-9]{2,19}$/', $name) ? Username::refusal($name, $request->user()?->id) : __('validation.custom.username.regex');

        return response()->json(['available' => $why === null, 'reason' => $why, 'suggestions' => $why === null ? [] : Username::suggestions($name)]);
    }

    /** The account's picture [X4]: any image up to game.account.avatar_max_kb, cut to a square and kept as a small JPEG. */
    public function avatar(Request $request): JsonResponse
    {
        $request->validate(['image' => ['required', 'image', 'mimes:jpeg,png,webp,gif', 'max:'.config('game.account.avatar_max_kb')]]);
        $jpeg = Avatar::square((string) file_get_contents($request->file('image')->getRealPath()), (int) config('game.account.avatar_size'));
        abort_unless($jpeg !== null, 422, 'تعذرت قراءة الصورة، جرّب صورة أخرى.');
        DB::table('user_avatars')->updateOrInsert(['user_id' => $request->user()->id], ['image' => $jpeg, 'updated_at' => GameClock::now()]);

        return response()->json(['user' => $request->user()->toAccount()]);
    }

    public function removeAvatar(Request $request): JsonResponse
    {
        DB::table('user_avatars')->where('user_id', $request->user()->id)->delete();

        return response()->json(['user' => $request->user()->toAccount()]);
    }

    public function showAvatar(User $user): Response
    {
        $image = DB::table('user_avatars')->where('user_id', $user->id)->value('image');
        abort_unless($image !== null, 404);

        return response($image, 200, ['Content-Type' => 'image/jpeg', 'Cache-Control' => 'public, max-age=604800, immutable']);
    }

    /** The account's holiday [X4]: every league stops counting the absence, so no team is lost meanwhile. */
    public function vacation(Request $request): JsonResponse
    {
        // [UP13] The days and the reason: up to 5 days at once, a longer one for the developers to decide.
        $data = $request->validate(['days' => ['required', 'integer', 'between:1,'.config('game.account.long_vacation_max_days')],
            'reason' => ['required', 'string', 'min:3', 'max:300']]);
        $row = AccountHolidays::request($request->user(), (int) $data['days'], trim($data['reason']));

        return response()->json(['user' => $request->user()->fresh()->toAccount(), 'vacation' => ['status' => $row->status, 'days' => (int) $row->days]]);
    }

    public function endVacation(Request $request): JsonResponse
    {
        Presence::endAccountHoliday($request->user());

        return response()->json(['user' => $request->user()->fresh()->toAccount()]);
    }

    /** Change the password, or give a Google-only account its first one. */
    public function password(Request $request): JsonResponse
    {
        $user = $request->user();
        $request->validate([
            'current_password' => [$user->hasPassword() ? 'required' : 'nullable', 'string'],
            'password' => ['required', 'string', $this->passwordRule()],
        ]);
        if ($user->hasPassword() && ! Hash::check((string) $request->input('current_password'), $user->password)) {
            throw ValidationException::withMessages(['current_password' => 'كلمة المرور الحالية غير صحيحة.']);
        }
        $user->update(['password' => $request->input('password')]);

        return response()->json(['user' => $user->toAccount()]);
    }

    /**
     * Deletes the account and everything that is only its own [PLAN 2.17]. Its teams go back
     * to the bots when leagues exist (Sprint 13). Asks for the password, or the email for a
     * Google-only account.
     */
    public function destroy(Request $request): JsonResponse
    {
        $user = $request->user();
        // The second confirmation [X12]: the word typed, on top of the password (or the email).
        $request->validate(['phrase' => ['required', 'string', 'in:احذف']], ['phrase.in' => 'اكتب كلمة «احذف» كما هي.', 'phrase.required' => 'اكتب كلمة «احذف» للتأكيد.']);
        if ($user->hasPassword()) {
            $request->validate(['password' => ['required', 'string']]);
            if (! Hash::check($request->input('password'), $user->password)) {
                throw ValidationException::withMessages(['password' => 'كلمة المرور غير صحيحة.']);
            }
        } else {
            $request->validate(['confirm' => ['required', 'string']]);
            if (Str::lower(trim($request->input('confirm'))) !== $user->email) {
                throw ValidationException::withMessages(['confirm' => 'اكتب بريدك كما هو لتأكيد الحذف.']);
            }
        }
        AccountDeletion::delete($user);
        Auth::guard('web')->logout();
        if ($request->hasSession()) {
            $request->session()->invalidate();
        }

        return response()->json(['deleted' => true]);
    }

    public function resend(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_if($user->hasVerifiedEmail(), 409, 'بريدك مؤكد من قبل.');
        // In production with no way out (no Brevo, Resend or Gmail settings) say so, rather than pretend it was sent [X8].
        // A developer's own address (OfficialAccounts) is told exactly why and how to fix it: the admin panel's
        // mail test needs the confirmed account this very email would make.
        $developer = OfficialAccounts::nameFor($user->email) !== null;
        $why = fn (string $base) => $developer ? $base.' السبب: '.(Mailer::$lastError ? substr(Mailer::$lastError, 0, 300).' الحل: '.Mailer::explain(Mailer::$lastError) : implode(' ', Mailer::setup()['problems'])) : $base;
        abort_if(app()->isProduction() && ! Mailer::live(), 503, $why('إرسال البريد غير مفعّل على الخادم بعد. تواصل مع الدعم ليفعّله.'));
        abort_unless(Mailer::attempt(fn () => $user->sendEmailVerificationNotification(), 'verify '.$user->id), 503,
            $why('تعذر إرسال الرسالة الآن. حاول بعد دقائق، أو تواصل مع الدعم.'));

        return response()->json(['sent' => true], 202);
    }

    /** Always the same answer, so nobody learns which emails have accounts. */
    public function forgot(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email']]);
        Mailer::attempt(fn () => Password::broker()->sendResetLink(['email' => Str::lower($data['email'])]), 'reset');

        return response()->json(['message' => 'إن كان البريد مسجلاً عندنا فستصلك رسالة فيها رابط لاختيار كلمة مرور جديدة.'], 202);
    }

    public function reset(Request $request): JsonResponse
    {
        $data = $request->validate([
            'token' => ['required', 'string'],
            'email' => ['required', 'email'],
            'password' => ['required', 'string', $this->passwordRule()],
        ]);
        $status = Password::broker()->reset(
            ['email' => Str::lower($data['email']), 'token' => $data['token'], 'password' => $data['password']],
            function (User $user, string $password) {
                $user->password = $password;
                $user->setRememberToken(Str::random(60));
                // Whoever knew the old password is signed out everywhere.
                $user->tokens()->delete();
                Sessions::forget($user->id);
                // The reset link reached this inbox, so the email is the user's.
                $user->email_verified_at ??= GameClock::now();
                $user->save();
                event(new PasswordReset($user));
            },
        );
        if ($status !== Password::PASSWORD_RESET) {
            throw ValidationException::withMessages(['email' => 'الرابط منتهي أو غير صحيح. اطلب رابطاً جديداً.']);
        }

        return response()->json(['reset' => true]);
    }

    /** The app's sign-in: a token that expires after game.app.token_ttl_days. */
    public function token(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'string', 'max:190'], 'password' => ['required', 'string'], 'device_name' => ['required', 'string', 'max:100']]);
        $user = User::where($this->loginField($data['email']), Str::lower(trim($data['email'])))->first();
        if (! $user || ! $user->hasPassword() || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages(['email' => self::WRONG]);
        }

        return response()->json($this->signIn($request, $user, $data['device_name']));
    }

    public function revoke(Request $request): JsonResponse
    {
        $token = $request->user()->currentAccessToken();
        abort_unless($token && method_exists($token, 'delete'), 400, 'هذا الطلب للتطبيق فقط.');
        $token->delete();

        return response()->json(['signed_out' => true]);
    }

    /** The app's Google sign-in: Google Sign-In on the phone sends its id_token here. */
    public function googleToken(Request $request, GoogleTokenVerifier $verifier, GoogleLinker $linker): JsonResponse
    {
        $data = $request->validate(['id_token' => ['required', 'string'], 'device_name' => ['required', 'string', 'max:100']]);
        $google = $verifier->verify($data['id_token']);
        if (! $google) {
            throw ValidationException::withMessages(['id_token' => 'تعذر التحقق من حساب جوجل. حاول مجدداً.']);
        }

        return response()->json($this->signIn($request, $linker->resolve($google), $data['device_name']));
    }

    /** [Sprint 50 M5] Playing as a guest: an account with no password, signed in by the app's token. */
    public function guest(Request $request): JsonResponse
    {
        $data = $request->validate(['device_name' => ['required', 'string', 'max:100']]);

        return response()->json($this->signIn($request, GuestAccounts::create(), $data['device_name']), 201);
    }

    /** [Sprint 50 M5] The guest keeps the account: a name, a username and a password, and an email if wanted. */
    public function keepGuest(Request $request): JsonResponse
    {
        $user = $request->user();
        GuestAccounts::assertGuest($user);
        $email = Str::lower(trim((string) $request->input('email')));
        $request->merge(['email' => $email !== '' ? $email : null]);
        $data = $request->validate([
            'name' => ['required', 'string', 'min:2', 'max:40'],
            'username' => ['required', 'string', Username::RULE, $this->usernameFree($user->id)],
            'email' => ['nullable', 'string', 'email', 'max:190', 'unique:users,email'],
            'password' => ['required', 'string', $this->passwordRule()],
        ]);

        return response()->json(['user' => GuestAccounts::keep($user, $data['name'], $data['username'], $data['password'], $data['email'] ?? null)->toAccount()]);
    }

    /** [Sprint 50 M5] The guest keeps the account with Google (GoogleLinker::attach). */
    public function keepGuestWithGoogle(Request $request, GoogleTokenVerifier $verifier, GoogleLinker $linker): JsonResponse
    {
        $data = $request->validate(['id_token' => ['required', 'string']]);
        $google = $verifier->verify($data['id_token']);
        if (! $google) {
            throw ValidationException::withMessages(['id_token' => 'تعذر التحقق من حساب جوجل. حاول مجدداً.']);
        }

        return response()->json(['user' => $linker->attach($request->user(), $google)->toAccount()]);
    }

    /** [Sprint 21 E2.4] Sends a one-time code to the account's email (or the one typed here, kept once verified). */
    public function sendVerificationCode(Request $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validate(['email' => [$user->email ? 'nullable' : 'required', 'string', 'email', 'max:190', Rule::unique('users', 'email')->ignore($user->id)]]);
        $email = Str::lower(trim((string) ($data['email'] ?? $user->email)));
        $sent = AccountVerification::send($user, $email);

        return response()->json(['sent' => $sent, 'email' => AccountVerification::masked($email), 'minutes' => (int) config('game.account.verify_code_minutes')]);
    }

    /** The code from the email: the account is verified, the welcome coins arrive, and the inviter's gift. */
    public function verifyAccount(Request $request): JsonResponse
    {
        $data = $request->validate(['code' => ['required', 'string', 'max:12']]);

        return response()->json(['user' => AccountVerification::verify($request->user(), $data['code'])->toAccount(),
            'coins' => (int) config('game.account.welcome_coins')]);
    }

    /** Signing in with an email or a username: an @ tells them apart, since a username has letters only. */
    private function loginField(string $login): string
    {
        return str_contains($login, '@') ? 'email' : 'username';
    }

    /** Signs the user in: a session for the web, or a token for the app when it names its device. */
    private function signIn(Request $request, User $user, ?string $device = null): array
    {
        // A developer's confirmed Gmail takes its reserved name and the admin panel [X11].
        OfficialAccounts::claim($user);
        Activity::record($user->id, 'logins');
        if ($device !== null) {
            $expires = GameClock::now()->addDays((int) config('game.app.token_ttl_days'));

            return ['user' => $user->toAccount(), 'token' => $user->createToken($device, ['*'], $expires)->plainTextToken, 'expires_at' => $expires->toIso8601ZuluString()];
        }
        if ($request->hasSession()) {
            Auth::guard('web')->login($user, (bool) $request->boolean('remember'));
            $request->session()->regenerate();
        }

        return ['user' => $user->toAccount()];
    }
}
