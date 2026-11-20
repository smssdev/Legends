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
        // بوابة: قاعدة واحدة بنعم أو لا ولها اسم
        Gate::define('admin', fn (User $user) => $user->isAdmin());

        // 5 محاولات في الدقيقة لكل عنوان وبريد
        RateLimiter::for('login', function (Request $request) {
            $key = $request->ip().'|'.Str::lower((string) $request->input('email'));

            return Limit::perMinute(5)->by($key)->response(function ($request, $headers) {
                $seconds = $headers['Retry-After'];

                return response()->json([
                    'message' => __('محاولات كثيرة. حاول مرة أخرى بعد :seconds ثانية.', ['seconds' => $seconds]),
                ], 429, $headers);
            });
        });
    }
}
