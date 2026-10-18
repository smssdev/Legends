<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

/** The simulator is off in production unless SIMULATOR_ENABLED=true. */
class SimulatorEnabled
{
    public function handle(Request $request, Closure $next)
    {
        abort_unless(config('game.simulator.enabled'), 404);

        return $next($request);
    }
}
