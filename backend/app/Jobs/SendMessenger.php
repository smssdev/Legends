<?php

namespace App\Jobs;

use App\Messenger\Telegram;
use App\Messenger\WhatsApp;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 67] One message from the game's bot to one chat (a coach, a league's group, the public channel). A chat that
 * no longer takes the bot's messages (he blocked it, the group removed it) is unlinked.
 */
class SendMessenger implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable;

    public int $tries = 2;

    /**
     * [Sprint 68] $buttons under the message (as Telegram::send), $replyTo the message it answers, and $stopPoll a
     * poll of the same chat to close first (the round's poll, settled with the result).
     */
    public function __construct(public string $platform, public string $chatId, public string $text, public bool $channel = false,
        public array $buttons = [], public ?int $replyTo = null, public ?int $stopPoll = null) {}

    public function handle(): void
    {
        if ($this->platform === 'whatsapp') {
            // [Sprint 70] Meta says his window is shut: the profile shows it, and nothing more is queued for him.
            if (WhatsApp::send($this->chatId, $this->text, $this->buttons) === 'closed') {
                DB::table('messenger_links')->where('platform', 'whatsapp')->where('chat_id', $this->chatId)->update(['last_inbound_at' => null]);
            }

            return;
        }
        if ($this->stopPoll) {
            Telegram::stopPoll($this->chatId, $this->stopPoll);
        }
        if (Telegram::send($this->chatId, $this->text, $this->buttons, null, $this->replyTo) === 'gone' && ! $this->channel) {
            DB::table('messenger_links')->where('platform', 'telegram')->where('chat_id', $this->chatId)->delete();
            DB::table('messenger_groups')->where('chat_id', $this->chatId)->delete();
        }
    }
}
