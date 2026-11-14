<?php

namespace App\Jobs;

use App\Messenger\Inline;
use App\Messenger\Telegram;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;

/** [Sprint 69] One «@bot» query answered (Telegram waits a few seconds for it, so it is never retried). */
class HandleInline implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable;

    public int $tries = 1;

    public function __construct(public string $queryId, public string $from, public string $query) {}

    public function handle(): void
    {
        Telegram::answerInline($this->queryId, Inline::results($this->from, mb_substr($this->query, 0, 64)));
    }
}
