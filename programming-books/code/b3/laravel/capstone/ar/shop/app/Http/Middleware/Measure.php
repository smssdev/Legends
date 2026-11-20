<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Redis;
use Symfony\Component\HttpFoundation\Response;

// سطر سجل JSON واحد وعدّاد واحد لكل طلب، أياً كانت الإجابة
class Measure
{
    public function handle(Request $request, Closure $next): Response
    {
        $start = hrtime(true);
        $response = $next($request);
        $route = $request->route()?->uri() ?? 'unknown';
        if (in_array($route, ['up', 'api/ready', 'api/metrics'])) {
            return $response;
        }
        $status = $response->getStatusCode();
        Redis::hincrby('metrics:requests', "{$request->method()}|$route|$status", 1);
        Log::info('request', [
            'method' => $request->method(),
            'url' => $request->getRequestUri(),
            'status' => $status,
            'ms' => intdiv(hrtime(true) - $start, 1_000_000),
        ]);

        return $response;
    }

    public static function metrics(): Response
    {
        $lines = ['# TYPE http_requests_total counter'];
        foreach (Redis::hgetall('metrics:requests') as $key => $count) {
            [$method, $route, $status] = explode('|', $key);
            $lines[] = "http_requests_total{method=\"$method\",route=\"/$route\",status=\"$status\"} $count";
        }

        return response(implode("\n", $lines)."\n", 200, ['Content-Type' => 'text/plain; version=0.0.4']);
    }
}
