<?php

namespace App\Console\Commands;

use App\Models\MasterClub;
use App\Simulator\Batch;
use Illuminate\Console\Command;

/** One fixture many times: results, goals, cards and fatigue (docs/ENGINE.md 9.3). */
class SimDuel extends Command
{
    protected $signature = 'sim:duel {home} {away} {--n=500} {--neutral : No home advantage} {--cup}
        {--tactics-home= : JSON tactics for the home team} {--tactics-away= : JSON tactics for the away team} {--json}';

    protected $description = 'Run one fixture many times and print the distribution';

    public function handle(): int
    {
        $home = MasterClub::where('name', $this->argument('home'))->firstOrFail();
        $away = MasterClub::where('name', $this->argument('away'))->firstOrFail();
        $overrides = [
            'home' => ['tactics' => json_decode($this->option('tactics-home') ?? 'null', true)],
            'away' => ['tactics' => json_decode($this->option('tactics-away') ?? 'null', true)],
        ];
        $options = ['venue' => $this->option('neutral') ? 'neutral' : 'home', 'competition' => $this->option('cup') ? 'cup' : 'league'];
        $summary = Batch::summary(Batch::run($home, $away, (int) $this->option('n'), $options, $overrides));

        if ($this->option('json')) {
            $this->line(json_encode($summary));
        } else {
            $this->info(sprintf('%s (%.1f) vs %s (%.1f)', $home->name, $home->strength_cp / 100, $away->name, $away->strength_cp / 100));
            $this->table(['metric', 'value'], collect($summary)->map(fn ($v, $k) => [$k, $v])->values()->all());
        }

        return self::SUCCESS;
    }
}
