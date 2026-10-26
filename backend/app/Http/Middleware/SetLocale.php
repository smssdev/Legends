<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * The language of the server's words [UP2]: English when the request asks for it first (Accept-Language, which the web
 * and the app send from the coach's saved choice), Arabic otherwise.
 */
class SetLocale
{
    public const LOCALES = ['ar', 'en'];

    public function handle(Request $request, Closure $next): Response
    {
        app()->setLocale(self::of($request));

        return $next($request);
    }

    public static function of(Request $request): string
    {
        $first = strtolower(substr(trim(explode(',', (string) $request->header('Accept-Language', ''))[0]), 0, 2));

        return in_array($first, self::LOCALES, true) ? $first : 'ar';
    }
}
