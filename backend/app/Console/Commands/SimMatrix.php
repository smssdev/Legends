<?php

namespace App\Console\Commands;

use App\Models\MasterClub;
use App\Simulator\Batch;
use Illuminate\Console\Command;

/**
 * Tactics matrix (docs/ENGINE.md 9.2): every attack plan against each
 * defensive shape, same club on both sides on a neutral ground. Fails when
 * any plan wins more than the configured share on average.
 */
class SimMatrix extends Command
{
    protected $signature = 'sim:matrix {--club=Liverpool} {--n=200}';

    protected $description = 'Win rate of each attack plan against each defensive shape';

    private const SHAPES = [
        'high' => ['pressing' => 85, 'style' => 65, 'trap' => 1],
        'mid' => ['pressing' => 50, 'style' => 50, 'trap' => 0],
        'low' => ['pressing' => 20, 'style' => 25, 'trap' => 0],
    ];

    public function handle(): int
    {
        $club = MasterClub::where('name', $this->option('club'))->firstOrFail();
        $limit = (int) config('game.engine.tactics_max_win_bp') / 100;
        $rows = [];
        $worst = 0;

        foreach (['counter', 'long', 'passing', 'wings', 'shots'] as $plan) {
            $row = [$plan];
            $sum = 0;
            foreach (self::SHAPES as $shape => $tactics) {
                $s = Batch::summary(Batch::run($club, $club, (int) $this->option('n'), ['venue' => 'neutral'],
                    ['home' => ['tactics' => ['plan' => $plan]], 'away' => ['tactics' => $tactics]]));
                $score = $s['home_win_%'] + $s['draw_%'] / 2;
                $row[] = $score;
                $sum += $score;
            }
            $avg = round($sum / count(self::SHAPES), 1);
            $row[] = $avg;
            $worst = max($worst, $avg);
            $rows[] = $row;
        }
        $this->table(['plan \\ shape (points %)', 'high', 'mid', 'low', 'average'], $rows);

        if ($worst > $limit) {
            $this->error("A plan averages {$worst}% (limit {$limit}%).");

            return self::FAILURE;
        }
        $this->info("No plan above {$limit}% on average.");

        return self::SUCCESS;
    }
}
