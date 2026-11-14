<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Messenger\Inbound;
use App\Messenger\Messenger;
use App\Messenger\Telegram;
use App\Messenger\WhatsApp;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Validation\Rule;

/**
 * [Sprint 67] The game's bots on Telegram and WhatsApp: the profile links and unlinks an account, and the two webhooks
 * hear what the coaches send (each checked as from Telegram, by the secret, or from Meta, by its signature).
 */
class MessengerController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return response()->json(Messenger::status($request->user()->id));
    }

    /** A one-time code, and the link that opens the bot's chat with it written. */
    public function link(Request $request): JsonResponse
    {
        $platform = $request->validate(['platform' => ['required', Rule::in(Messenger::PLATFORMS)]])['platform'];
        abort_unless(Messenger::available($platform), 409, $platform === 'telegram' ? 'بوت تيليجرام غير مفعّل بعد.' : 'بوت واتساب غير مفعّل بعد.');
        $code = Messenger::code($request->user()->id);

        return response()->json($code + ['platform' => $platform, 'url' => Messenger::openUrl($platform, $code['code'])], 201);
    }

    public function update(Request $request, string $platform): JsonResponse
    {
        abort_unless(in_array($platform, Messenger::PLATFORMS, true), 404);
        Messenger::mute($request->user()->id, $platform, $request->validate(['muted' => ['required', 'boolean']])['muted']);

        return response()->json(Messenger::status($request->user()->id));
    }

    public function unlink(Request $request, string $platform): JsonResponse
    {
        abort_unless(in_array($platform, Messenger::PLATFORMS, true), 404);
        Messenger::unlink($request->user()->id, $platform);

        return response()->json(Messenger::status($request->user()->id));
    }

    public function telegram(Request $request): Response
    {
        abort_unless(Telegram::configured(), 404);
        abort_unless(hash_equals((string) config('services.telegram.secret'), (string) $request->header('X-Telegram-Bot-Api-Secret-Token')), 403);
        Inbound::telegram($request->json()->all());

        return response()->noContent(200);
    }

    /** Meta's check when the webhook is set: the verify word back, its challenge answered. */
    public function whatsappVerify(Request $request): Response
    {
        abort_unless(WhatsApp::configured(), 404);
        abort_unless($request->query('hub_mode') === 'subscribe'
            && hash_equals((string) config('services.whatsapp.verify'), (string) $request->query('hub_verify_token')), 403);

        return response((string) $request->query('hub_challenge'), 200, ['Content-Type' => 'text/plain']);
    }

    public function whatsapp(Request $request): Response
    {
        abort_unless(WhatsApp::configured(), 404);
        abort_unless(WhatsApp::signed($request->getContent(), $request->header('X-Hub-Signature-256')), 403);
        Inbound::whatsapp($request->json()->all());

        return response()->noContent(200);
    }
}
