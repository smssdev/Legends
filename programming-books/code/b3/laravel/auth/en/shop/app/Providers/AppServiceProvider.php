<?php

namespace App\Providers;

use App\Models\User;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;

class AppServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        // a gate: one yes-or-no rule with a name
        Gate::define('admin', fn (User $user) => $user->isAdmin());

        // 5 attempts a minute per address and email
        RateLimiter::for('login', function (Request $request) {
            $key = $request->ip().'|'.Str::lower((string) $request->input('email'));

            return Limit::perMinute(5)->by($key)->response(function ($request, $headers) {
                $seconds = $headers['Retry-After'];

                return response()->json([
                    'message' => __('Too many attempts. Try again in :seconds seconds.', ['seconds' => $seconds]),
                ], 429, $headers);
            });
        });
    }
}
