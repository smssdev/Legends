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
        $this->line((string) self::busy((int) $this->option('soon')));

        return self::SUCCESS;
    }

    /** The matches live now, and those kicking off within $soon minutes; also the admin panel's "safe to deploy" [X33]. */
    public static function busy(int $soon = 0): int
    {
        $live = DB::table('matches')->where('status', 'live')->count();
        if ($soon > 0) {
            $live += DB::table('fixtures')->whereIn('status', ['scheduled', 'locked'])->where('is_bye', false)->whereNotNull('home_id')->whereNotNull('away_id')
                ->whereBetween('scheduled_at', [GameClock::now()->subMinutes(15), GameClock::now()->addMinutes($soon)])->count();
        }

        return $live;
    }
}
