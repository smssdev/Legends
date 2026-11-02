<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * The admin panel: an admin's account, signed in on the site [Sprint 37]. [Sprint 39 A1] Its email (or username) and
 * password only: the two-step code is gone (the owner's request, 2026-11-02).
 */
class AdminOnly
{
    public function handle(Request $request, Closure $next): Response
    {
        abort_unless($request->user()?->isAdmin(), 403, 'لوحة الإدارة للمدير فقط.');
        abort_unless($request->hasSession(), 403, 'لوحة الإدارة من الموقع فقط.');
        // [Sprint 30 G6] An admin with a scope opens only its sections (game.admin.scopes: the paths under /admin/).
        if ($scope = $request->user()->admin_scope) {
            $section = explode('/', substr($request->path(), strlen('api/v1/admin/')))[0];
            abort_unless($section === 'access' || in_array($section, config('game.admin.scopes')[$scope] ?? [], true), 403, 'هذا القسم خارج صلاحياتك في الإدارة.');
        }

        return $next($request);
    }
}
