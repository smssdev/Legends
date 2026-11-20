<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

// An API speaks JSON both ways: answers are always JSON, bodies must be.
final class RequireJson
{
    public function handle(Request $request, Closure $next): Response
    {
        $request->headers->set('Accept', 'application/json');
        $sendsBody = in_array($request->method(), ['POST', 'PUT', 'PATCH'], true);
        abort_if($sendsBody && ! $request->isJson(), 415, 'Send JSON.');
        return $next($request);
    }
}
