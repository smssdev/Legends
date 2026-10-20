<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

/**
 * The simulator: open in development (and the demo, SIMULATOR_ENABLED=true); elsewhere for
 * admins only [Sprint 10 B3]. Hidden behind a 404 for everyone else.
 */
class SimulatorEnabled
{
    public function handle(Request $request, Closure $next)
    {
        abort_unless(config('game.simulator.enabled') || $request->user('sanctum')?->isAdmin(), 404);

        return $next($request);
    }
}
