<?php

namespace App\Http\Controllers\Api;

use App\Events\ServerPing;
use App\Http\Controllers\Controller;
use App\Support\GameClock;
use Illuminate\Broadcasting\BroadcastException;
use Illuminate\Http\JsonResponse;

/**
 * GET /health: what the web and the app check first. The app compares its own
 * version with min_app_version and asks for an update when it is older [PLAN 1].
 */
class HealthController extends Controller
{
    public function show(): JsonResponse
    {
        return response()->json([
            'status' => 'ok',
            'version' => config('app.version'),
            'min_app_version' => config('game.app.min_version'),
            'engine_version' => config('game.engine.version'),
            'time' => GameClock::now()->toIso8601ZuluString(),
            'clock_offset' => GameClock::offset(),
            'broadcast' => ['channel' => ServerPing::CHANNEL, 'event' => ServerPing::NAME],
            'support' => self::support(),
        ]);
    }

    /** The support buttons' links [X13]: null for a channel with no number or username. */
    public static function support(): array
    {
        $number = preg_replace('/\D+/', '', (string) config('game.support.whatsapp'));
        $telegram = ltrim(trim((string) config('game.support.telegram')), '@');
        $text = rawurlencode((string) config('game.support.message'));

        return [
            'whatsapp' => $number !== '' ? "https://wa.me/{$number}?text={$text}" : null,
            'telegram' => preg_match('/^[A-Za-z0-9_]{5,32}$/', $telegram) ? "https://t.me/{$telegram}" : null,
        ];
    }

    /** POST /health/ping: sends the test event, so a screen can see broadcasting work end to end. */
    public function ping(): JsonResponse
    {
        $event = new ServerPing(GameClock::now()->toIso8601ZuluString());
        try {
            broadcast($event);
        } catch (BroadcastException) {
            abort(503, 'خادم البث لا يعمل. شغّله بـ php artisan reverb:start');
        }

        return response()->json(['sent' => true, 'at' => $event->at], 202);
    }
}
