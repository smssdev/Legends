<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

// يضيف الوقت الذي أمضاه التطبيق في الطلب، وتعرضه أدوات المطور في المتصفحات.
final class AddServerTiming
{
    public function handle(Request $request, Closure $next): Response
    {
        $start = hrtime(true);
        $response = $next($request); // everything after this middleware runs here
        $ms = (hrtime(true) - $start) / 1_000_000;
        $response->headers->set('Server-Timing', sprintf('app;dur=%.1f', $ms));

        return $response;
    }
}
