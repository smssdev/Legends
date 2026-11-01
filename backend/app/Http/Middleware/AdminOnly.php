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
        // [Sprint 30 G6] An admin with a scope opens only its sections (game.admin.scopes: the paths under /admin/).
        if ($scope = $request->user()->admin_scope) {
            $section = explode('/', substr($request->path(), strlen('api/v1/admin/')))[0];
            abort_unless($section === '2fa' || in_array($section, config('game.admin.scopes')[$scope] ?? [], true), 403, 'هذا القسم خارج صلاحياتك في الإدارة.');
        }

        return $next($request);
    }
}
