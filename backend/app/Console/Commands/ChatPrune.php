<?php

namespace App\Console\Commands;

use App\Chat\ChatGroups;
use Illuminate\Console\Command;

/** [X65] Delete the chat groups' messages older than the admin's retention (hourly; nothing while it is 0). */
class ChatPrune extends Command
{
    protected $signature = 'chat:prune {--days= : This many days instead of the admin\'s setting}';

    protected $description = 'Delete chat messages older than the retention set in the admin panel';

    public function handle(): int
    {
        $days = $this->option('days');
        $n = ChatGroups::prune($days === null ? null : (int) $days);
        $this->info("Chat: {$n} old messages deleted.");

        return self::SUCCESS;
    }
}
