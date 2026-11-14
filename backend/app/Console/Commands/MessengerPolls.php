<?php

namespace App\Console\Commands;

use App\Messenger\LeagueGroups;
use Illuminate\Console\Command;

/** [Sprint 68] The polls before each round in the leagues' Telegram groups (every ten minutes). */
class MessengerPolls extends Command
{
    protected $signature = 'messenger:polls';

    protected $description = 'Post the round polls in the league groups';

    public function handle(): int
    {
        $this->info('Polls: '.LeagueGroups::polls().'.');

        return self::SUCCESS;
    }
}
