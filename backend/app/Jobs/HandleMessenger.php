<?php

namespace App\Jobs;

use App\Messenger\ChatBridge;
use App\Messenger\LeagueGroups;
use App\Messenger\Messenger;
use App\Messenger\Replies;
use App\Messenger\Telegram;
use App\Messenger\WhatsApp;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 67] One message a coach (or a league's Telegram group) sent to the game's bot, answered: the reply is made
 * here on the queue and sent back on the same chat. Once: a failed answer is not retried (he can ask again).
 */
class HandleMessenger implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable;

    public int $tries = 1;

    public int $timeout = 60;

    /** @param  string|null  $from  the Telegram account that wrote in a group (null in a private chat) */
    public function __construct(public string $platform, public string $chatId, public string $text, public ?string $from = null) {}

    public function handle(Replies $replies): void
    {
        if ($this->from !== null) {
            $text = $this->group();
            if ($text !== null) {
                Telegram::send($this->chatId, $text);
            }

            return;
        }
        $reply = $replies->answer($this->platform, $this->chatId, $this->text);
        foreach ([$reply, ...($reply['more'] ?? [])] as $r) {
            if ($r['text'] === '') {
                continue;
            }
            $this->platform === 'telegram'
                ? Telegram::send($this->chatId, $r['text'], $r['buttons'], $r['keyboard'] ?? null)
                : WhatsApp::send($this->chatId, $r['text'], $r['buttons']);
        }
    }

    /** A command in a league's Telegram group: link it, unlink it, the table, or what the bot does there. */
    private function group(): ?string
    {
        // [Sprint 69] A member's words in a group joined to the game's chat: carried there, nothing answered.
        if (! str_starts_with(trim($this->text), '/')) {
            ChatBridge::fromTelegram($this->chatId, (string) $this->from, $this->text);

            return null;
        }
        $parts = preg_split('/\s+/u', Replies::normal($this->text)) ?: [''];
        $userId = Messenger::userFor('telegram', (string) $this->from);
        $en = $userId && DB::table('users')->where('id', $userId)->value('locale') === 'en';
        $league = LeagueGroups::leagueOf($this->chatId);

        return match ($parts[0]) {
            'league' => match (true) {
                ! $userId => "اربط حسابك بالبوت في محادثة خاصة أولاً، ثم أرسل الأمر هنا.\nLink your account with the bot in a private chat first.",
                ! isset($parts[1]) => $en ? 'Send: /league CODE' : 'أرسل: /league كود_الدوري',
                default => ($l = LeagueGroups::link($userId, $parts[1], $this->chatId))
                    ? ($en ? "This group now gets the results of {$l->name} after each round." : "هذا الجروب مربوط الآن بدوري {$l->name}: تصله النتائج بعد كل جولة.")
                    : ($en ? 'Only the league\'s owner can link it, with its code.' : 'لا يربط الدوري إلا منشئه، بكوده.'),
            },
            'unleague' => $userId && LeagueGroups::unlink($userId, $this->chatId)
                ? ($en ? 'Unlinked: no more results here.' : 'فُك ربط الجروب: لن تصله النتائج.')
                : ($en ? 'Only the league\'s owner can unlink it.' : 'لا يفك الربط إلا منشئ الدوري.'),
            'table' => $league && ($season = DB::table('seasons')->where('league_id', $league)->orderByDesc('id')->value('id'))
                ? LeagueGroups::tableText((int) $season, $en)
                : ($en ? 'No league is linked to this group.' : 'لا دوري مربوطاً بهذا الجروب.'),
            // [Sprint 69] The owner joins the group to the league's chat in the game, or parts them.
            'chat' => $userId && isset($parts[1]) && in_array($parts[1], ['on', 'off'], true) && ChatBridge::set($userId, $this->chatId, $parts[1] === 'on')
                ? ($parts[1] === 'on'
                    ? ($en ? 'This group and the league\'s chat in the game are one now: members who linked the bot write here or there.' : 'صار هذا الجروب وجروب الدوري في اللعبة واحداً: من ربط حسابه بالبوت يكتب هنا أو هناك.')
                    : ($en ? 'This group and the game\'s chat are apart again.' : 'فُصل هذا الجروب عن جروب الدوري في اللعبة.'))
                : ($en ? 'Only the league\'s owner can: /chat on or /chat off.' : 'لا يغيّرها إلا منشئ الدوري: /chat on أو /chat off.'),
            // [Sprint 68] The owner turns the live goals in the group on or off.
            'goals' => $userId && isset($parts[1]) && in_array($parts[1], ['on', 'off'], true) && LeagueGroups::live($userId, $this->chatId, $parts[1] === 'on')
                ? ($parts[1] === 'on' ? ($en ? 'The goals are posted here live.' : 'تُنشر الأهداف هنا مباشرة.') : ($en ? 'No more live goals here.' : 'أوقفت نشر الأهداف المباشرة هنا.'))
                : ($en ? 'Only the league\'s owner can: /goals on or /goals off.' : 'لا يغيّرها إلا منشئ الدوري: /goals on أو /goals off.'),
            'help', 'start' => $en
                ? "In a league's group I post each round's results and stars, the goals live, and a poll before each round.\n/league CODE: the owner links his league\n/table: the table\n/goals on|off: the live goals\n/chat on|off: join this group to the game's chat\n/unleague: unlink"
                : "في جروب الدوري أنشر نتائج كل جولة ونجومها، والأهداف مباشرة، واستطلاعاً قبل كل جولة.\n/league الكود: يربط المنشئ دوريه\n/table: الترتيب\n/goals on|off: الأهداف المباشرة\n/chat on|off: ربط الجروب بجروب الدوري في اللعبة\n/unleague: فك الربط",
            default => null,
        };
    }
}
