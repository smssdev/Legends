<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

// Arabic stays Arabic in every JSON answer, not \u0643
final class UnescapedJson
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);
        if ($response instanceof JsonResponse) {
            $options = $response->getEncodingOptions();
            $options |= JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES;
            $response->setEncodingOptions($options);
        }

        return $response;
    }
}
