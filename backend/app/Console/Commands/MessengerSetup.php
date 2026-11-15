<?php

namespace App\Console\Commands;

use App\Messenger\Messenger;
use App\Messenger\Replies;
use App\Messenger\Telegram;
use App\Messenger\WhatsApp;
use Illuminate\Console\Command;

/**
 * [Sprint 67] Once after the bots' keys are set on the server (legends-set), and again after each deploy that changes
 * the bots: points Telegram at the game's webhook, and prints what to write in Meta's dashboard for WhatsApp's.
 * [Sprint 70] Also what each bot says of itself (Telegram's description, WhatsApp's business profile), the «/» menu
 * in groups, and what is still missing, step by step (BotFather's switches, Meta's number and subscription).
 */
class MessengerSetup extends Command
{
    protected $signature = 'messenger:setup';

    protected $description = 'Point the Telegram bot at the game and show the WhatsApp webhook settings';

    /** The group commands Telegram shows by «/» in a group. */
    private const GROUP_COMMANDS = [
        'table' => ['ترتيب الدوري', 'The league table'], 'league' => ['يربط المنشئ دوريه: /league الكود', 'The owner links his league: /league CODE'],
        'goals' => ['الأهداف المباشرة: /goals on أو off', 'Live goals: /goals on or off'], 'chat' => ['ربط الجروب بجروب اللعبة: /chat on أو off', 'Join the game\'s chat: /chat on or off'],
        'unleague' => ['فك ربط الدوري', 'Unlink the league'], 'help' => ['ماذا يفعل البوت هنا', 'What the bot does here'],
    ];

    public function handle(): int
    {
        $base = rtrim((string) config('app.url'), '/').'/api/v1/messenger';
        $site = rtrim((string) config('app.frontend_url'), '/');
        if (Telegram::configured()) {
            $r = Telegram::setWebhook("{$base}/telegram");
            $this->line($r['ok'] ? "Telegram: the webhook is {$base}/telegram." : 'Telegram: failed: '.$r['description']);
            $this->channel();
            // [Sprint 68] The menu by «/», in Arabic (the default) and in English; [Sprint 70] and the groups' own.
            $ar = Telegram::setCommands(array_map(fn ($d) => $d[0], Replies::TELEGRAM_COMMANDS));
            $en = Telegram::setCommands(array_map(fn ($d) => $d[1], Replies::TELEGRAM_COMMANDS), 'en');
            $gAr = Telegram::setGroupCommands(array_map(fn ($d) => $d[0], self::GROUP_COMMANDS));
            $gEn = Telegram::setGroupCommands(array_map(fn ($d) => $d[1], self::GROUP_COMMANDS), 'en');
            $this->line($ar && $en && $gAr && $gEn ? 'Telegram: the commands menus are set (private chats and groups).' : 'Telegram: a commands menu failed.');
            $said = Telegram::describe("لعبة المدرب الأسطورة: مدرب كرة قدم أونلاين.\nاربط حسابك من ملفك في اللعبة ({$site}/profile) لتسألني عن مباراتك وترتيبك، وتدير مباراتك الحية، وتصلك إشعاراتك هنا.",
                'بوت لعبة المدرب الأسطورة: مباراتك وترتيبك وإشعاراتك.')
                && Telegram::describe("Game Legend Manager, the online football manager.\nLink your account from your profile in the game ({$site}/profile) to ask me about your match and table, run your live match, and get your notifications here.",
                    'The bot of Game Legend Manager: your match, table and notifications.', 'en');
            $this->line($said ? 'Telegram: the bot\'s description is set.' : 'Telegram: the description failed.');
            $this->abilities();
        } else {
            $this->warn('Telegram: off (TELEGRAM_BOT_TOKEN and TELEGRAM_WEBHOOK_SECRET are not set).');
        }
        $this->whatsapp($base, $site);

        return self::SUCCESS;
    }

    /** [Sprint 70] What only BotFather can switch on, said when it is off. */
    private function abilities(): void
    {
        $me = Telegram::abilities();
        if ($me === null) {
            $this->warn('Telegram: getMe failed (is the token right?).');

            return;
        }
        if ($me['username'] && $me['username'] !== Telegram::username()) {
            $this->warn("Telegram: the bot is @{$me['username']}: set TELEGRAM_BOT_USERNAME={$me['username']} with legends-set.");
        }
        $me['inline']
            ? $this->line('Telegram: @bot in any chat is on.')
            : $this->warn('Telegram: @bot in any chat is off: in @BotFather send /setinline, choose the bot, and write «نتائجي وترتيبي».');
        $me['groups']
            ? $this->line('Telegram: the bot reads the groups\' talk (for /chat on).')
            : $this->line('Telegram: the bot reads only commands in groups. For /chat on make it an admin of the league\'s group, or in @BotFather /setprivacy → the bot → Disable.');
    }

    private function whatsapp(string $base, string $site): void
    {
        if (! WhatsApp::configured()) {
            $missing = array_keys(array_filter(['WHATSAPP_TOKEN' => 'token', 'WHATSAPP_PHONE_ID' => 'phone_id', 'WHATSAPP_APP_SECRET' => 'app_secret',
                'WHATSAPP_VERIFY_TOKEN' => 'verify'], fn ($k) => ! config("services.whatsapp.{$k}")));
            $this->warn('WhatsApp: off. Still to set with legends-set: '.implode(', ', $missing).'.');

            return;
        }
        $this->line("WhatsApp: in Meta's dashboard (WhatsApp, Configuration), the callback URL is {$base}/whatsapp,");
        $this->line('the verify token is WHATSAPP_VERIFY_TOKEN as set on the server, and the field to subscribe is «messages».');
        $phone = WhatsApp::phone();
        if (isset($phone['error'])) {
            $this->warn('WhatsApp: Meta refused the number: '.$phone['error'].' (check WHATSAPP_PHONE_ID and that WHATSAPP_TOKEN is a permanent System User token).');
        } elseif ($phone) {
            $this->line(sprintf('WhatsApp: the number is %s, «%s», quality %s, name %s.', $phone['display_phone_number'] ?? '?', $phone['verified_name'] ?? '?',
                $phone['quality_rating'] ?? '?', $phone['name_status'] ?? '?'));
            $mine = WhatsApp::number();
            if ($mine && preg_replace('/\D/', '', (string) ($phone['display_phone_number'] ?? '')) !== $mine) {
                $this->warn('WhatsApp: WHATSAPP_NUMBER is not the number Meta has for WHATSAPP_PHONE_ID.');
            }
        }
        if (! WhatsApp::number()) {
            $this->warn('WhatsApp: set WHATSAPP_NUMBER (the bot\'s number, digits only) so the profile can open the chat.');
        }
        $this->line(WhatsApp::profile('بوت لعبة المدرب الأسطورة: مباراتك وترتيبك وإشعاراتك.',
            "Game Legend Manager، لعبة مدرب كرة القدم أونلاين. اربط حسابك من ملفك في اللعبة ({$site}/profile) ثم اسألني عن مباراتك وترتيبك ورصيدك، وتصلك إشعاراتك هنا.", $site)
            ? 'WhatsApp: the business profile is set.' : 'WhatsApp: the business profile failed (the token may lack whatsapp_business_management).');
        $business = (string) config('services.whatsapp.business_id');
        if ($business === '') {
            $this->line('WhatsApp: set WHATSAPP_BUSINESS_ID (the WhatsApp Business Account id) so the app is subscribed to its messages.');
        } else {
            $why = WhatsApp::subscribe($business);
            $why === null ? $this->line('WhatsApp: the app is subscribed to the business account\'s messages.') : $this->warn("WhatsApp: the subscription failed: {$why}");
        }
    }

    /** [Sprint 67 X] The public channel: the link the site shows, and whether the bot can post there. */
    private function channel(): void
    {
        if (trim((string) config('services.telegram.channel')) === '') {
            $this->line('Telegram channel: none (TELEGRAM_CHANNEL is not set).');

            return;
        }
        ['chat' => $chat, 'url' => $url] = Messenger::telegramChannel();
        $this->line('Telegram channel: the site links to '.($url ?? 'nothing (set TELEGRAM_CHANNEL_URL to its invite link)').'.');
        if ($chat === null) {
            $this->warn('Telegram channel: an invite link cannot be posted to: set TELEGRAM_CHANNEL to the channel\'s @name, or to its number (-100…) for a private one.');

            return;
        }
        $why = Telegram::canPost($chat);
        $why === null
            ? $this->line("Telegram channel: the bot posts to {$chat}.")
            : $this->warn("Telegram channel: the bot cannot post to {$chat}: {$why}. Add the bot to the channel as an admin.");
    }
}
