<?php

namespace App\Http\Middleware;

use App\Support\Activity;
use App\Support\GameClock;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Symfony\Component\HttpFoundation\Response;

/**
 * A signed-in visit counts for the day [PLAN 2.22, Sprint 37], recorded after the answer: at most one every ten
 * minutes per account, so the requests of one screen are one visit and SQLite is not written on each request.
 */
class RecordActivity
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);
        // Not for an account this request deleted.
        $user = $request->user();
        if ($user?->exists && Cache::add('visit:'.$user->id.':'.intdiv(GameClock::now()->timestamp, 600), 1, 600)) {
            Activity::record($user->id, 'visits');
        }

        return $response;
    }
}
