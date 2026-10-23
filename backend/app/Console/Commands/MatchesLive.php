<?php

namespace App\Console\Commands;

use App\Support\GameClock;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * How many matches are live now, and with --soon=N those kicking off in the next N minutes too. The update script
 * waits for zero before it deploys [PLAN 2.12, Sprint 37]: no deploy while a match is played, nor right before one.
 */
class MatchesLive extends Command
{
    protected $signature = 'matches:live {--soon=0 : Count the matches kicking off within this many minutes too}';

    protected $description = 'Count the matches being played now';

    public function handle(): int
    {
        $live = DB::table('matches')->where('status', 'live')->count();
        $soon = (int) $this->option('soon');
        if ($soon > 0) {
            $live += DB::table('fixtures')->whereIn('status', ['scheduled', 'locked'])->where('is_bye', false)->whereNotNull('home_id')->whereNotNull('away_id')
                ->whereBetween('scheduled_at', [GameClock::now()->subMinutes(15), GameClock::now()->addMinutes($soon)])->count();
        }
        $this->line((string) $live);

        return self::SUCCESS;
    }
}
