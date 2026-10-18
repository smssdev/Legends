<?php

namespace App\Console\Commands;

use App\Models\MasterClub;
use App\Simulator\Batch;
use Illuminate\Console\Command;

/**
 * Isolation test for one tactic knob (docs/ENGINE.md 9.2): the home team
 * changes one value, everything else stays fixed, on a neutral ground.
 */
class SimSweep extends Command
{
    protected $signature = 'sim:sweep {knob : pressing|style|tempo|tackling|trap} {--home=Liverpool} {--away=Arsenal}
        {--from=0} {--to=100} {--step=25} {--n=300}';

    protected $description = 'Sweep one tactic value and show its effect';

    public function handle(): int
    {
        $home = MasterClub::where('name', $this->option('home'))->firstOrFail();
        $away = MasterClub::where('name', $this->option('away'))->firstOrFail();
        $knob = $this->argument('knob');
        $rows = [];

        for ($v = (int) $this->option('from'); $v <= (int) $this->option('to'); $v += max(1, (int) $this->option('step'))) {
            $s = Batch::summary(Batch::run($home, $away, (int) $this->option('n'), ['venue' => 'neutral'], ['home' => ['tactics' => [$knob => $v]]]));
            $rows[] = [$v, $s['home_win_%'], $s['draw_%'], $s['goals_home'], $s['goals_away'], $s['attacks_home'], $s['counters_away'],
                $s['yellow_home'], $s['red_home_%'], $s['fitness_end_home_%']];
        }
        $this->table([$knob, 'win %', 'draw %', 'GF', 'GA', 'attacks', 'counters vs', 'yellow', 'red %', 'fitness end %'], $rows);

        return self::SUCCESS;
    }
}
