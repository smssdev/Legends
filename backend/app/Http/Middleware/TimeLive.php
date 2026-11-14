<?php

namespace App\Http\Middleware;

use App\Admin\ServerPulse;
use App\Support\GameClock;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** [Sprint 66 B3] Times the live match's answer for the admin panel's pulse (App\Admin\ServerPulse). */
class TimeLive
{
    public function handle(Request $request, Closure $next): Response
    {
        $start = GameClock::stopwatchNs();
        $response = $next($request);
        ServerPulse::record(intdiv(GameClock::stopwatchNs() - $start, 1_000_000));

        return $response;
    }
}
