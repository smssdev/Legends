<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Big JSON answers go gzipped when the browser accepts it [E1.3]: the season's calendar or a squad are tens of KB
 * of repeated keys, a tenth of that gzipped, which matters on a phone and on the server's bandwidth. A proxy in
 * front that compresses too leaves an answer that already has Content-Encoding as it is.
 */
class CompressJson
{
    private const MIN_BYTES = 2048;

    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);
        $body = $response->getContent();
        if ($body === false || strlen($body) < self::MIN_BYTES || $response->headers->has('Content-Encoding')
            || ! str_contains((string) $response->headers->get('Content-Type'), 'json')
            || ! str_contains((string) $request->header('Accept-Encoding'), 'gzip') || ! function_exists('gzencode')) {
            return $response;
        }
        $response->setContent(gzencode($body, 5));
        $response->headers->set('Content-Encoding', 'gzip');
        $response->headers->set('Vary', trim($response->headers->get('Vary', '').', Accept-Encoding', ', '));
        $response->headers->remove('Content-Length');

        return $response;
    }
}
