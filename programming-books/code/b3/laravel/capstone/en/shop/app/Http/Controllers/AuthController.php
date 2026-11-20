<?php

namespace App\Http\Controllers;

use App\Http\Problem;
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
        $request->merge(['email' => Str::lower((string) $request->input('email'))]);
        $data = $request->validate([
            'email' => ['required', 'email', 'max:254'],
            'name' => ['required', 'string', 'max:100'],
            'password' => ['required', 'string', Password::min(12), 'max:128'],
        ]);
        try {
            $user = User::create($data);
        } catch (UniqueConstraintViolationException) {
            throw Problem::emailTaken();
        }

        return response()->json($user->only('id', 'email', 'name'), 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'string', 'max:254'],
            'password' => ['required', 'string', 'max:128'],
        ]);
        $user = User::where('email', Str::lower($data['email']))->first();
        // an unknown email still costs one hash, so timing does not reveal which emails exist
        $ok = Hash::check($data['password'], $user->password ?? self::dummy());
        if (! $user || ! $ok) {
            throw Problem::badLogin();
        }
        // Sanctum stores only the token's hash: a leaked table opens no account
        $token = $user->createToken('api', ['*'], now()->addDays(30))->plainTextToken;

        return response()->json(['token' => $token]);
    }

    private static function dummy(): string
    {
        static $hash;

        return $hash ??= Hash::make('not anyone\'s password');
    }
}
