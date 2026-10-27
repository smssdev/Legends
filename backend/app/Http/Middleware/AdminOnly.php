<?php

namespace App\Http\Middleware;

use App\Admin\TwoFactor;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** The admin panel: an admin's account, signed in on the site, who proved the two-step code when it is asked [Sprint 37, X46]. */
class AdminOnly
{
    public function handle(Request $request, Closure $next): Response
    {
        abort_unless($request->user()?->isAdmin(), 403, 'لوحة الإدارة للمدير فقط.');
        abort_unless($request->hasSession(), 403, 'لوحة الإدارة من الموقع فقط.');
        abort_unless(TwoFactor::passed(), 423, 'أدخل رمز التحقق بخطوتين.');

        return $next($request);
    }
}
