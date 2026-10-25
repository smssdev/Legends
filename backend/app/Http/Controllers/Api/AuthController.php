<?php

namespace App\Http\Controllers\Api;

use App\Auth\GoogleLinker;
use App\Auth\GoogleTokenVerifier;
use App\Auth\OfficialAccounts;
use App\Auth\Username;
use App\Http\Controllers\Controller;
use App\League\Leaving;
use App\League\Presence;
use App\Models\LeagueMembership;
use App\Models\User;
use App\Support\Activity;
use App\Support\Avatar;
use App\Support\GameClock;
use App\Support\Mailer;
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

    private function passwordRule(): PasswordRule
    {
        return PasswordRule::min(8)->letters()->numbers();
    }

    public function register(Request $request): JsonResponse
    {
        $request->merge(['email' => Str::lower(trim((string) $request->input('email')))]);
        $data = $request->validate([
            'name' => ['required', 'string', 'min:2', 'max:40'],
            'username' => ['required', 'string', Username::RULE, $this->usernameFree()],
            'email' => ['required', 'string', 'email', 'max:190', 'unique:users,email'],
            'password' => ['required', 'string', 'confirmed', $this->passwordRule()],
            'terms' => ['accepted'],
            'device_name' => ['sometimes', 'string', 'max:100'],
        ]);
        $user = User::create(['name' => trim($data['name']), 'username' => $data['username'], 'email' => $data['email'], 'password' => $data['password']]);
        // The account is made even if the email cannot leave now: the banner in the app sends it again [X8].
        $sent = Mailer::attempt(fn () => $user->sendEmailVerificationNotification(), 'verify '.$user->id);

        return response()->json($this->signIn($request, $user, $data['device_name'] ?? null) + ['verification_sent' => $sent && Mailer::live()], 201);
    }

    public function login(Request $request): JsonResponse
    {
        abort_unless($request->hasSession(), 400, 'الدخول بالجلسة للويب فقط. التطبيق يستخدم /auth/token.');
        // The email or the username [X4].
        $data = $request->validate(['email' => ['required', 'string', 'max:190'], 'password' => ['required', 'string'], 'remember' => ['sometimes', 'boolean']]);
        if (! Auth::guard('web')->attempt([$this->loginField($data['email']) => Str::lower(trim($data['email'])), 'password' => $data['password']], (bool) ($data['remember'] ?? false))) {
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

    public function me(Request $request): JsonResponse
    {
        return response()->json(['user' => $request->user()->toAccount()]);
    }

    /** The name and the username [X4], the commentator [X9] and the simulator [X10]; any of them may be sent alone. */
    public function update(Request $request): JsonResponse
    {
        $user = $request->user();
        $data = $request->validate([
            'name' => ['required_without_all:username,commentator,match_view', 'string', 'min:2', 'max:40'],
            'username' => ['sometimes', 'string', Username::RULE, $this->usernameFree($user->id)],
            'commentator' => ['sometimes', 'string', Rule::in(config('game.viewing.commentators'))],
            'match_view' => ['sometimes', 'string', Rule::in(config('game.viewing.match_views'))],
        ]);
        $user->update(array_filter(['name' => isset($data['name']) ? trim($data['name']) : null,
            'username' => isset($data['username']) ? strtolower($data['username']) : null,
            'commentator' => $data['commentator'] ?? null, 'match_view' => $data['match_view'] ?? null]));

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
        $data = $request->validate(['days' => ['required', 'integer', 'between:1,'.config('game.account.vacation_max_days')]]);
        Presence::startAccountHoliday($request->user(), (int) $data['days']);

        return response()->json(['user' => $request->user()->fresh()->toAccount()]);
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
        DB::transaction(function () use ($user) {
            $user->tokens()->delete();
            DB::table('sessions')->where('user_id', $user->id)->delete();
            DB::table('password_reset_tokens')->where('email', $user->email)->delete();
            // Its clubs go back to the bots, as any coach leaving: offers and listings cancelled [PLAN 2.2, Sprint 37].
            foreach (LeagueMembership::where('user_id', $user->id)->whereNull('left_at')->get() as $m) {
                Leaving::leave($m, 'deleted');
            }
            // What is only its own goes with it (wallet, messages, devices, activity: by the database's cascades);
            // what the leagues keep (titles, objectives, matches) loses the name.
            $user->delete();
        });
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
        abort_if(app()->isProduction() && ! Mailer::live(), 503, 'إرسال البريد غير مفعّل على الخادم بعد. تواصل مع الدعم ليفعّله.');
        abort_unless(Mailer::attempt(fn () => $user->sendEmailVerificationNotification(), 'verify '.$user->id), 503,
            'تعذر إرسال الرسالة الآن. حاول بعد دقائق، أو تواصل مع الدعم.');

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
                DB::table('sessions')->where('user_id', $user->id)->delete();
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
