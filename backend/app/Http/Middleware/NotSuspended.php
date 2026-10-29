<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * A suspended account [Sprint 21 E7.3] reads only who it is (to be told why) and can sign out; every other request
 * is refused with the reason the developers gave.
 */
class NotSuspended
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if ($user?->suspended_at && ! $request->is('api/v1/auth/me', 'api/v1/auth/logout', 'api/v1/support', 'api/v1/support/*')) {
            abort(403, $user->suspended_reason ? 'حسابك معلّق من فريق التطوير: '.$user->suspended_reason : 'حسابك معلّق من فريق التطوير.');
        }

        return $next($request);
    }
}
