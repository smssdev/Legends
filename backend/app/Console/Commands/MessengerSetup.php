<?php

namespace App\Console\Commands;

use App\Messenger\Telegram;
use App\Messenger\WhatsApp;
use Illuminate\Console\Command;

/**
 * [Sprint 67] Once after the bots' keys are set on the server (legends-set): points Telegram at the game's webhook,
 * and prints what to write in Meta's dashboard for WhatsApp's.
 */
class MessengerSetup extends Command
{
    protected $signature = 'messenger:setup';

    protected $description = 'Point the Telegram bot at the game and show the WhatsApp webhook settings';

    public function handle(): int
    {
        $base = rtrim((string) config('app.url'), '/').'/api/v1/messenger';
        if (Telegram::configured()) {
            $r = Telegram::setWebhook("{$base}/telegram");
            $this->line($r['ok'] ? "Telegram: the webhook is {$base}/telegram." : 'Telegram: failed: '.$r['description']);
            $name = Telegram::me();
            if ($name && $name !== Telegram::username()) {
                $this->warn("Telegram: the bot is @{$name}: set TELEGRAM_BOT_USERNAME={$name} with legends-set.");
            }
        } else {
            $this->warn('Telegram: off (TELEGRAM_BOT_TOKEN and TELEGRAM_WEBHOOK_SECRET are not set).');
        }
        if (WhatsApp::configured()) {
            $this->line("WhatsApp: in Meta's dashboard (WhatsApp, Configuration), the callback URL is {$base}/whatsapp,");
            $this->line('the verify token is WHATSAPP_VERIFY_TOKEN as set on the server, and the field to subscribe is «messages».');
            if (! WhatsApp::number()) {
                $this->warn('WhatsApp: set WHATSAPP_NUMBER (the bot\'s number, digits only) so the profile can open the chat.');
            }
        } else {
            $this->warn('WhatsApp: off (WHATSAPP_TOKEN, WHATSAPP_PHONE_ID, WHATSAPP_APP_SECRET and WHATSAPP_VERIFY_TOKEN are not all set).');
        }

        return self::SUCCESS;
    }
}
