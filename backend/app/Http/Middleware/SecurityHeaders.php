<?php

namespace App\Http\Middleware;

use App\Http\Security\SecurityPolicy;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Every answer's security headers [E1.2], from App\Http\Security\SecurityPolicy (the web server's router sends the same
 * on the pages it serves itself, Sprint 51 B1): no sniffing, no framing by other sites, no referrer to other sites, no
 * camera, the microphone for this site alone, HSTS behind HTTPS, the enforced CSP and the full one in report-only mode.
 */
class SecurityHeaders
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);
        foreach (SecurityPolicy::headers($request->isSecure()) as $name => $value) {
            // A route that set its own policy keeps it.
            if (str_starts_with($name, 'Content-Security-Policy') && $response->headers->has($name)) {
                continue;
            }
            $response->headers->set($name, $value);
        }
        $response->headers->remove('X-Powered-By');

        return $response;
    }
}
