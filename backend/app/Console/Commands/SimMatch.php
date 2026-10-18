<?php

namespace App\Console\Commands;

use App\Models\MasterClub;
use App\Simulator\MatchFactory;
use App\Simulator\Runner;
use Illuminate\Console\Command;

/** Plays one match in the terminal (docs/ENGINE.md 9.3). */
class SimMatch extends Command
{
    protected $signature = 'sim:match {home : Home club name} {away : Away club name}
        {--seed=1 : Match seed} {--cup : Cup rules (extra time and penalties)} {--json : Print the result and every tick as JSON}';

    protected $description = 'Simulate a single match between two real clubs';

    public function handle(): int
    {
        $home = MasterClub::where('name', $this->argument('home'))->firstOrFail();
        $away = MasterClub::where('name', $this->argument('away'))->firstOrFail();
        $state = MatchFactory::make($home, $away, ['seed' => (int) $this->option('seed'), 'competition' => $this->option('cup') ? 'cup' : 'league']);
        [$state, $ticks] = Runner::toEnd($state);

        if ($this->option('json')) {
            $this->line(json_encode(['score' => $state['score'], 'shootout' => $state['shootout'], 'ticks' => $ticks], JSON_UNESCAPED_UNICODE));

            return self::SUCCESS;
        }

        $name = fn ($side, $id) => collect($state['teams'][$side]['players'])->firstWhere('id', $id)['name'] ?? '?';
        foreach ($ticks as $tick) {
            foreach ($tick['events'] as $e) {
                $line = match ($e['type']) {
                    'goal' => 'GOAL '.$name($e['team'], $e['scorer']).' ('.$e['score']['home'].'-'.$e['score']['away'].')',
                    'card' => strtoupper($e['color']).' '.$name($e['team'], $e['player']),
                    'sub' => 'SUB '.$name($e['team'], $e['in']).' for '.$name($e['team'], $e['out']),
                    'period' => strtoupper($e['name']),
                    'stoppage' => '+'.$e['added'].' added',
                    'penalty' => 'PENALTY '.($e['scored'] ? 'scored' : 'missed'),
                    'shootout' => 'SHOOTOUT '.$e['score']['home'].'-'.$e['score']['away'],
                    default => null,
                };
                if ($line) {
                    $this->line(sprintf("%3d'%-3s %-5s %s", $tick['minute'][0], $tick['minute'][1] ? '+'.$tick['minute'][1] : '', $e['team'] ?? '', $line));
                }
            }
        }
        $this->info(sprintf('%s %d - %d %s', $home->name, $state['score']['home'], $state['score']['away'], $away->name));
        foreach (['home', 'away'] as $side) {
            $this->line($side.' '.$state['teams'][$side]['formation'].': '.json_encode($state['teams'][$side]['stats']));
        }

        return self::SUCCESS;
    }
}
