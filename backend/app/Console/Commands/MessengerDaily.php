<?php

namespace App\Console\Commands;

use App\Jobs\SendMessenger;
use App\Messenger\Messenger;
use App\Messenger\Reads;
use App\Support\GameClock;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 68] Every hour: the daily summary to each linked bot whose coach chose this Cairo hour («daily 8»), once a
 * day (a conditional update takes the day). Not to a silenced bot, and on WhatsApp only inside its free window.
 */
class MessengerDaily extends Command
{
    protected $signature = 'messenger:daily';

    protected $description = 'Send the daily summary to the coaches who chose this hour';

    public function handle(): int
    {
        $cairo = GameClock::now()->setTimezone('Africa/Cairo');
        $today = $cairo->toDateString();
        $links = DB::table('messenger_links')->join('users', 'users.id', '=', 'messenger_links.user_id')
            ->where('messenger_links.daily_hour', $cairo->hour)->where('messenger_links.muted', false)
            ->where(fn ($q) => $q->whereNull('messenger_links.daily_sent_on')->orWhere('messenger_links.daily_sent_on', '<', $today))
            ->get(['messenger_links.*', 'users.locale']);
        $n = 0;
        foreach ($links as $l) {
            if (! Messenger::available($l->platform) || ($l->platform === 'whatsapp' && ! Messenger::windowOpen($l->last_inbound_at))) {
                continue;
            }
            if (DB::table('messenger_links')->where('id', $l->id)->where(fn ($q) => $q->whereNull('daily_sent_on')->orWhere('daily_sent_on', '<', $today))
                ->update(['daily_sent_on' => $today]) !== 1) {
                continue;
            }
            $text = Reads::daily((int) $l->user_id, $l->locale === 'en' ? 'en' : 'ar');
            if ($text !== null) {
                SendMessenger::dispatch($l->platform, $l->chat_id, $text);
                $n++;
            }
        }
        $this->info("Daily summaries: {$n}.");

        return self::SUCCESS;
    }
}
