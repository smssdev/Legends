<?php

namespace App\Http\Middleware;

use App\Models\SimMatch;
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
        abort_unless(config('game.simulator.enabled') || $request->user('sanctum')?->isAdmin() || self::intro($request), 404);

        return $next($request);
    }

    /**
     * [Sprint 64 B1] The new coach's intro match plays wherever the simulator is off: its own route (signed in), and the
     * match it made (marked in its setup), never another simulator match.
     */
    private static function intro(Request $request): bool
    {
        if (str_starts_with($request->path(), 'api/v1/sim/intro')) {
            return true;
        }
        $match = $request->route('match');
        $match = $match instanceof SimMatch ? $match : (is_string($match) ? SimMatch::find($match) : null);

        return (bool) ($match?->setup['intro'] ?? false);
    }
}
