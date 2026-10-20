<?php

namespace App\Http\Controllers\Api;

use App\Auth\GoogleLinker;
use App\Auth\GoogleTokenVerifier;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\Activity;
use App\Support\GameClock;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
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
            'email' => ['required', 'string', 'email', 'max:190', 'unique:users,email'],
            'password' => ['required', 'string', $this->passwordRule()],
            'terms' => ['accepted'],
            'device_name' => ['sometimes', 'string', 'max:100'],
        ]);
        $user = User::create(['name' => trim($data['name']), 'email' => $data['email'], 'password' => $data['password']]);
        $user->sendEmailVerificationNotification();

        return response()->json($this->signIn($request, $user, $data['device_name'] ?? null), 201);
    }

    public function login(Request $request): JsonResponse
    {
        abort_unless($request->hasSession(), 400, 'الدخول بالجلسة للويب فقط. التطبيق يستخدم /auth/token.');
        $data = $request->validate(['email' => ['required', 'email'], 'password' => ['required', 'string'], 'remember' => ['sometimes', 'boolean']]);
        if (! Auth::guard('web')->attempt(['email' => Str::lower($data['email']), 'password' => $data['password']], (bool) ($data['remember'] ?? false))) {
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

    public function update(Request $request): JsonResponse
    {
        $data = $request->validate(['name' => ['required', 'string', 'min:2', 'max:40']]);
        $request->user()->update(['name' => trim($data['name'])]);

        return response()->json(['user' => $request->user()->toAccount()]);
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
        $user->sendEmailVerificationNotification();

        return response()->json(['sent' => true], 202);
    }

    /** Always the same answer, so nobody learns which emails have accounts. */
    public function forgot(Request $request): JsonResponse
    {
        $data = $request->validate(['email' => ['required', 'email']]);
        Password::broker()->sendResetLink(['email' => Str::lower($data['email'])]);

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
        $data = $request->validate(['email' => ['required', 'email'], 'password' => ['required', 'string'], 'device_name' => ['required', 'string', 'max:100']]);
        $user = User::where('email', Str::lower($data['email']))->first();
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

    /** Signs the user in: a session for the web, or a token for the app when it names its device. */
    private function signIn(Request $request, User $user, ?string $device = null): array
    {
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
