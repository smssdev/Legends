<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        // البُرد بأحرف صغيرة: Lina@Example.com هو lina@example.com
        $request->merge(['email' => Str::lower((string) $request->input('email'))]);
        $data = $request->validate([
            'email' => ['required', 'email', 'max:254', 'unique:users'],
            'name' => ['required', 'string', 'max:100'],
            'password' => ['required', 'string', Password::min(12), 'max:128'],
        ]);
        try {
            $user = User::create($data)->refresh();
        } catch (UniqueConstraintViolationException) {
            // تسجيلان معاً: الفهرس الفريد يقرر، لا قاعدة التحقق
            abort(409, __('البريد مسجّل من قبل.'));
        }

        return response()->json($user->only('id', 'email', 'name', 'role'), 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'string', 'max:254'],
            'password' => ['required', 'string', 'max:128'],
        ]);
        $user = User::where('email', Str::lower($data['email']))->first();
        // البريد المجهول يكلّف تجزئة أيضاً: الوقت لا يكشف شيئاً
        $ok = Hash::check($data['password'], $user->password ?? self::dummy());
        // الجواب نفسه لبريد خطأ ولكلمة مرور خطأ
        if (! $user || ! $ok) {
            abort(401, __('البريد أو كلمة المرور خطأ.'));
        }
        // لا يحفظ Sanctum إلا SHA-256 للرمز؛ والعميل يأخذ النسخة الوحيدة
        $token = $user->createToken('api', ['*'], now()->addDays(30))->plainTextToken;

        return response()->json(['token' => $token, 'expires_in' => 30 * 24 * 3600]);
    }

    public function logout(Request $request): JsonResponse
    {
        // الرمز الذي أرسل هذا الطلب وحده
        $request->user()->currentAccessToken()->delete();

        return response()->json(null, 204);
    }

    // التمرين 4: الخروج من كل الأجهزة
    public function logoutAll(Request $request): JsonResponse
    {
        $request->user()->tokens()->delete();

        return response()->json(null, 204);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json($user->only('id', 'email', 'name', 'role'));
    }

    private static function dummy(): string
    {
        static $hash;

        return $hash ??= Hash::make('not anyone\'s password');
    }
}
