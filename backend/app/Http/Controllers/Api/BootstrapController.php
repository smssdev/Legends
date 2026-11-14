<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Messages\Inbox;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;

/**
 * [Sprint 58 B1] GET /bootstrap: what the web asks once when it opens, in one reply (it was five to nine requests, W-P06).
 * Who is signed in (GET /auth/me), the coins wallet (GET /wallet), the coach and his slots (GET /home's coach and
 * slots), the unread count (GET /messages/unread), and the site's settings from GET /health (the support links,
 * AdSense, the measurement, the broadcast ping). Each part is the same as its own route's, which stays (the app uses
 * them until Sprint 61, and the web reloads a part from its route after a change). Open to a guest: then the user and
 * the coach's parts are null.
 */
class BootstrapController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $config = Arr::only(app(HealthController::class)->show()->getData(true), ['version', 'time', 'clock_offset', 'broadcast', 'support', 'bots', 'adsense', 'analytics']);
        $user = $request->user('sanctum');
        // A token that no longer works (the app's) gets the 401 that sends it to sign in again, as GET /auth/me.
        if (! $user && $request->bearerToken()) {
            throw new AuthenticationException;
        }
        if (! $user) {
            return response()->json(['user' => null, 'wallet' => null, 'home' => null, 'unread' => 0, 'config' => $config]);
        }
        $request->setUserResolver(fn () => $user);
        $home = app(HomeController::class)->show($request)->getData(true);

        return response()->json([
            'user' => $user->toAccount(),
            'wallet' => app(WalletController::class)->show($request)->getData(true),
            'home' => Arr::only($home, ['coach', 'slots']),
            'unread' => Inbox::unread($user->id),
            'config' => $config,
        ]);
    }
}
