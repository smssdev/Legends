<?php

namespace App\Notify;

use App\Support\GameClock;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

/**
 * [Sprint 19 B1] Firebase Cloud Messaging for the Android app, on the same channel as Web Push (App\Notify\Push).
 * HTTP v1 with the project's service account: its JSON file sits on the server (FCM_CREDENTIALS, a path Suleiman sets
 * with legends-set, never in the repository); without it nothing is sent. The access token is signed here (RS256,
 * openssl) and kept for 50 minutes. The app's own Firebase settings (not secret) reach it from /app (client()).
 */
class Fcm
{
    public static function configured(): bool
    {
        return self::account() !== null;
    }

    /** The app's Firebase settings, or null until all four are set on the server. */
    public static function client(): ?array
    {
        $c = config('game.notifications.fcm.client');

        return $c['api_key'] && $c['app_id'] && $c['project_id'] && $c['sender_id'] ? $c : null;
    }

    /** One message to one device: "ok", "gone" (the token is dead: forget it) or "error" (try another time). */
    public static function send(string $token, array $payload): string
    {
        $account = self::account();
        if (! $account) {
            return 'error';
        }
        $r = Http::timeout(10)->withToken(self::accessToken($account))->post(
            "https://fcm.googleapis.com/v1/projects/{$account['project_id']}/messages:send",
            ['message' => [
                'token' => $token,
                'notification' => ['title' => (string) $payload['title'], 'body' => (string) $payload['body']],
                // The tap opens the screen of the message's link (the app maps the site's paths to its own).
                'data' => ['link' => (string) ($payload['link'] ?? '/'), 'tag' => (string) ($payload['tag'] ?? ''), 'league' => (string) ($payload['league'] ?? '')],
                'android' => ['priority' => 'high', 'notification' => ['tag' => (string) ($payload['tag'] ?? '')]],
            ]],
        );
        if ($r->successful()) {
            return 'ok';
        }
        $code = $r->json('error.details.0.errorCode') ?? $r->json('error.status');

        return $r->status() === 404 || in_array($code, ['UNREGISTERED', 'INVALID_ARGUMENT'], true) ? 'gone' : 'error';
    }

    /** The service account, read from its file; null when it is not there or not one. */
    private static function account(): ?array
    {
        $path = config('game.notifications.fcm.credentials');
        if (! $path || ! is_file($path)) {
            return null;
        }
        $a = json_decode((string) file_get_contents($path), true);

        return is_array($a) && isset($a['client_email'], $a['private_key'], $a['project_id']) ? $a : null;
    }

    private static function accessToken(array $account): string
    {
        return Cache::remember('fcm.token.'.md5($account['client_email']), 3000, function () use ($account) {
            $b64 = fn (string $s) => rtrim(strtr(base64_encode($s), '+/', '-_'), '=');
            // Google checks the token's time against the real one: the game clock without a development time travel.
            $now = GameClock::now()->getTimestamp() - GameClock::offset();
            $head = $b64(json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
            $claims = $b64(json_encode([
                'iss' => $account['client_email'], 'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud' => 'https://oauth2.googleapis.com/token', 'iat' => $now, 'exp' => $now + 3600,
            ]));
            openssl_sign("{$head}.{$claims}", $signature, $account['private_key'], OPENSSL_ALGO_SHA256);

            return (string) Http::asForm()->timeout(10)->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer', 'assertion' => "{$head}.{$claims}.".$b64($signature),
            ])->throw()->json('access_token');
        });
    }
}
