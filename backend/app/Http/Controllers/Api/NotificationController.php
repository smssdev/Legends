<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Notify\Fcm;
use App\Notify\MatchEmail;
use App\Notify\Push;
use App\Store\Store;
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
            // [Sprint 19 B1] Whether the server can push to the Android app.
            'app_enabled' => Fcm::configured(),
            'devices' => DB::table('push_subscriptions')->where('user_id', $user->id)->count(),
            'kinds' => array_map(fn ($k) => ['kind' => $k, 'on' => Push::wants($user->id, $k)], array_keys(config('game.notifications.kinds'))),
            // [X79] The match summary by email: the account's choice (off by default), and whether it can arrive.
            'email_match' => MatchEmail::wants($user->id),
            // [Sprint 43 W2] The store's offers by email: also the account's choice, off by default.
            'email_offers' => Store::wantsEmail($user->id),
            'email_ready' => (bool) $user->email && $user->email_verified_at !== null,
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $kinds = array_keys(config('game.notifications.kinds'));
        $data = $request->validate(['kinds' => 'required_without_all:email_match,email_offers|array', 'kinds.*' => 'boolean', 'email_match' => 'sometimes|boolean', 'email_offers' => 'sometimes|boolean']);
        $prefs = json_decode((string) $request->user()->notify_prefs, true) ?: [];
        foreach (['email_match', 'email_offers'] as $key) {
            if (array_key_exists($key, $data)) {
                $prefs[$key] = (bool) $data[$key];
            }
        }
        foreach ($data['kinds'] ?? [] as $kind => $on) {
            abort_unless(in_array($kind, $kinds, true), 422, 'نوع إشعار غير معروف.');
            $prefs[$kind] = (bool) $on;
        }
        DB::table('users')->where('id', $request->user()->id)->update(['notify_prefs' => json_encode($prefs)]);

        return $this->show($request);
    }

    /** This browser subscribes (or renews its subscription); or [Sprint 19 B1] this app, by its FCM token. */
    public function subscribe(Request $request): JsonResponse
    {
        $now = GameClock::now();
        if ($request->input('channel') === 'fcm') {
            $data = $request->validate(['token' => 'required|string|max:600']);
            DB::table('push_subscriptions')->upsert([[
                'user_id' => $request->user()->id, 'channel' => 'fcm', 'endpoint' => $data['token'], 'p256dh' => null, 'auth' => null,
                'created_at' => $now, 'updated_at' => $now,
            ]], ['endpoint'], ['user_id', 'updated_at']);

            return $this->show($request);
        }
        $data = $request->validate([
            'endpoint' => 'required|url|max:600',
            'keys.p256dh' => 'required|string|max:200',
            'keys.auth' => 'required|string|max:100',
            'channel' => ['nullable', Rule::in(['webpush'])],
        ]);
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
