<?php

namespace App\Http\Middleware;

use App\League\Presence;
use App\Models\League;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** Any visit to a league's pages counts as the coach's activity there [PLAN 2.2]. */
class LeagueActivity
{
    public function handle(Request $request, Closure $next): Response
    {
        // Before the answer, so the screen already shows the warning cleared. Only a coach's own
        // active membership in this league is touched, so a refused request changes nothing.
        $league = $request->route('league');
        $id = $league instanceof League ? $league->id : (is_numeric($league) ? (int) $league : null);
        if ($id && $request->user()) {
            Presence::touch($request->user()->id, $id);
        }

        return $next($request);
    }
}
