<?php

namespace App\Console\Commands;

use App\Models\MasterClub;
use App\Simulator\Batch;
use Illuminate\Console\Command;

/**
 * Knob isolation (docs/ENGINE.md 9.2): one club against itself on a neutral
 * ground, the home side moving a single knob from its low to its high value on
 * the same seeds. Each knob must move its numbers the expected way
 * (config game.balance.knobs) and must not shift the points share by more
 * than max_win_shift. Fails otherwise.
 */
class SimKnobs extends Command
{
    protected $signature = 'sim:knobs {--club=Liverpool} {--n=400} {--knob= : Only this knob} {--json}';

    protected $description = 'Isolation test for every tactic knob';

    public function handle(): int
    {
        $club = MasterClub::where('name', $this->option('club'))->firstOrFail();
        $cfg = config('game.balance');
        $n = (int) $this->option('n');
        $rows = [];
        $failed = 0;

        foreach ($cfg['knobs'] as $knob => $k) {
            if ($this->option('knob') && $this->option('knob') !== $knob) {
                continue;
            }
            $run = fn (int $v) => Batch::summary(Batch::run($club, $club, $n, ['venue' => 'neutral'], ['home' => ['tactics' => [$knob => $v]], 'away' => ['tactics' => $k['against'] ?? null]]));
            $low = $run($k['from']);
            $high = $run($k['to']);
            $points = fn ($s) => $s['home_win_%'] + $s['draw_%'] / 2;
            $shift = round($points($high) - $points($low), 1);
            // The points share of a batch of n varies by about 42 / sqrt(n) points (two batches: × sqrt 2); allow two of those on top.
            $limit = $cfg['max_win_shift'] + round(120 / sqrt($n), 1);
            $ok = abs($shift) <= $limit;
            $failed += $ok ? 0 : 1;
            $rows[] = [$knob, 'points %', $points($low), $points($high), "±{$limit}", $ok ? 'ok' : 'OUT'];

            foreach ($k['expect'] as $metric => $way) {
                $ok = ($high[$metric] - $low[$metric]) * $way > 0;
                $failed += $ok ? 0 : 1;
                $rows[] = [$knob, $metric, $low[$metric], $high[$metric], $way > 0 ? 'up' : 'down', $ok ? 'ok' : 'OUT'];
            }
        }

        if ($this->option('json')) {
            $this->line(json_encode(['passed' => $failed === 0, 'rows' => $rows]));
        } else {
            $this->table(['knob', 'metric', 'low', 'high', 'expected', ''], $rows);
        }
        if ($failed) {
            $this->error("{$failed} check(s) failed.");

            return self::FAILURE;
        }
        $this->info('Every knob moves the way it should.');

        return self::SUCCESS;
    }
}
