<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Notify\Push;
use App\Support\GameClock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/** Notifications [PLAN 2.13, Sprint 36]: which kinds an account wants, and the browsers it gets them on. */
class NotificationController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'public_key' => config('game.notifications.vapid.public'),
            'enabled' => Push::configured(),
            'devices' => DB::table('push_subscriptions')->where('user_id', $user->id)->count(),
            'kinds' => array_map(fn ($k) => ['kind' => $k, 'on' => Push::wants($user->id, $k)], array_keys(config('game.notifications.kinds'))),
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $kinds = array_keys(config('game.notifications.kinds'));
        $data = $request->validate(['kinds' => 'required|array', 'kinds.*' => 'boolean']);
        $prefs = json_decode((string) $request->user()->notify_prefs, true) ?: [];
        foreach ($data['kinds'] as $kind => $on) {
            abort_unless(in_array($kind, $kinds, true), 422, 'نوع إشعار غير معروف.');
            $prefs[$kind] = (bool) $on;
        }
        DB::table('users')->where('id', $request->user()->id)->update(['notify_prefs' => json_encode($prefs)]);

        return $this->show($request);
    }

    /** This browser subscribes (or renews its subscription). */
    public function subscribe(Request $request): JsonResponse
    {
        $data = $request->validate([
            'endpoint' => 'required|url|max:600',
            'keys.p256dh' => 'required|string|max:200',
            'keys.auth' => 'required|string|max:100',
            'channel' => ['nullable', Rule::in(['webpush'])],
        ]);
        $now = GameClock::now();
        DB::table('push_subscriptions')->upsert([[
            'user_id' => $request->user()->id, 'channel' => 'webpush', 'endpoint' => $data['endpoint'],
            'p256dh' => $data['keys']['p256dh'], 'auth' => $data['keys']['auth'], 'created_at' => $now, 'updated_at' => $now,
        ]], ['endpoint'], ['user_id', 'p256dh', 'auth', 'updated_at']);

        return $this->show($request);
    }

    public function unsubscribe(Request $request): JsonResponse
    {
        $data = $request->validate(['endpoint' => 'required|string|max:600']);
        DB::table('push_subscriptions')->where('user_id', $request->user()->id)->where('endpoint', $data['endpoint'])->delete();

        return $this->show($request);
    }
}
