<?php

namespace App\Console\Commands;

use App\Jobs\SendMessenger;
use App\League\NextFixture;
use App\Messenger\Messenger;
use App\Messenger\Reads;
use App\Support\GameClock;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 70] WhatsApp writes to a coach for free only within 24 hours of his own last message. Shortly before that
 * window shuts (game.messenger.whatsapp_warn_hours), a coach with a match in the next day is told once, with «استمر»
 * under it: one tap opens the window again, so his match's notifications keep reaching him. Itself inside the window,
 * so free; never to a silenced bot, and once a window (the window's start is in the key).
 */
class MessengerWindow extends Command
{
    protected $signature = 'messenger:whatsapp-window';

    protected $description = 'Tell the WhatsApp coaches with a match tomorrow that their free window is about to shut';

    public function handle(): int
    {
        if (! Messenger::available('whatsapp')) {
            return self::SUCCESS;
        }
        $now = GameClock::now();
        $window = (int) config('game.messenger.whatsapp_window_hours');
        $warn = (int) config('game.messenger.whatsapp_warn_hours');
        $links = DB::table('messenger_links')->join('users', 'users.id', '=', 'messenger_links.user_id')
            ->where('messenger_links.platform', 'whatsapp')->where('messenger_links.muted', false)
            ->where('messenger_links.last_inbound_at', '>', $now->copy()->subHours($window))
            ->where('messenger_links.last_inbound_at', '<=', $now->copy()->subHours($window - $warn))
            ->get(['messenger_links.*', 'users.locale']);
        $n = 0;
        foreach ($links as $l) {
            if (! $this->matchSoon((int) $l->user_id, $now->copy()->addDay())
                || ! Cache::add("messenger:wa-window:{$l->chat_id}:".Carbon::parse($l->last_inbound_at)->timestamp, true, 2 * 86400)) {
                continue;
            }
            $en = $l->locale === 'en';
            SendMessenger::dispatch('whatsapp', $l->chat_id, $en
                ? "You have a match soon. My messages here stop in about {$warn} hours unless you write to me (WhatsApp's rule). Tap «Keep» to keep them coming."
                : "عندك مباراة قريبة. رسائلي هنا تتوقف بعد نحو {$warn} ساعة ما لم تراسلني (قاعدة واتساب). اضغط «استمر» لتبقى تصلك.",
                false, [[$en ? 'Keep' : 'استمر', 'keep']]);
            $n++;
        }
        $this->info("WhatsApp reminders: {$n}.");

        return self::SUCCESS;
    }

    /** One of his clubs plays before $until (or is playing now). */
    private function matchSoon(int $userId, Carbon $until): bool
    {
        foreach (Reads::clubs($userId) as $c) {
            $f = NextFixture::of((int) $c->id);
            if ($f && ($f->status === 'live' || Carbon::parse($f->scheduled_at)->lte($until))) {
                return true;
            }
        }

        return false;
    }
}
