<?php

namespace App\Console\Commands;

use App\League\MatchReplay;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * [X78] Keeps the scene of every finished match played on this engine that has none yet (match_replays), so it can
 * still be watched after the engine changes. Run by deploy/vps/deploy.sh before every deploy, while the old engine
 * still runs; safe to run again (a kept match is skipped).
 */
class MatchesKeepReplays extends Command
{
    protected $signature = 'matches:keep-replays {--limit=0 : At most this many matches (0: all)}';

    protected $description = 'Keep the replay of every finished match of this engine version';

    public function handle(): int
    {
        $query = DB::table('matches')->where('status', 'finished')->where('engine_version', (int) config('game.engine.version'))
            ->whereNotIn('id', DB::table('match_replays')->select('match_id'))->orderBy('id');
        if ((int) $this->option('limit') > 0) {
            $query->limit((int) $this->option('limit'));
        }
        $kept = 0;
        $failed = 0;
        foreach ($query->pluck('id') as $id) {
            try {
                $kept += MatchReplay::keep(DB::table('matches')->where('id', $id)->first()) ? 1 : 0;
            } catch (\Throwable $e) {
                $failed++;
                $this->warn("Match {$id}: ".$e->getMessage());
            }
        }
        $this->info("Kept {$kept} replays".($failed ? ", {$failed} failed" : '').'.');

        return self::SUCCESS;
    }
}
