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
        // emails in lower case: Lina@Example.com is lina@example.com
        $request->merge(['email' => Str::lower((string) $request->input('email'))]);
        $data = $request->validate([
            'email' => ['required', 'email', 'max:254', 'unique:users'],
            'name' => ['required', 'string', 'max:100'],
            'password' => ['required', 'string', Password::min(12), 'max:128'],
        ]);
        try {
            $user = User::create($data)->refresh();
        } catch (UniqueConstraintViolationException) {
            // two registrations at once: the unique index decides, not the rule
            abort(409, __('Email already registered.'));
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
        // an unknown email still costs one hash: the time reveals nothing
        $ok = Hash::check($data['password'], $user->password ?? self::dummy());
        // the same answer for a wrong email and a wrong password
        if (! $user || ! $ok) {
            abort(401, __('Email or password is wrong.'));
        }
        // Sanctum stores only the SHA-256 of the token; the client gets the only copy
        $token = $user->createToken('api', ['*'], now()->addDays(30))->plainTextToken;

        return response()->json(['token' => $token, 'expires_in' => 30 * 24 * 3600]);
    }

    public function logout(Request $request): JsonResponse
    {
        // only the token that made this request
        $request->user()->currentAccessToken()->delete();

        return response()->json(null, 204);
    }

    // exercise 4: sign out on every device
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
