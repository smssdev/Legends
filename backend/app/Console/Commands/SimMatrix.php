<?php

namespace App\Console\Commands;

use App\League\TacticsBook;
use App\Models\MasterClub;
use App\Simulator\Batch;
use Illuminate\Console\Command;

/**
 * Tactics matrix (docs/ENGINE.md 9.2): every attack plan against each
 * defensive shape, same club on both sides on a neutral ground. Fails when
 * any plan wins more than the configured share on average.
 *
 * [Sprint 21 E5.4] Then the underdog: the weakest club of the same league against the club holding each shape. With the
 * plan the tactics book names for that shape it must take at least engine.counter_edge_min_pts more points (of 100)
 * than with the plans the book does not name, so the weaker side always has an answer on the pitch.
 */
class SimMatrix extends Command
{
    protected $signature = 'sim:matrix {--club=Liverpool} {--underdog=} {--n=200}';

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

        return $this->underdog($club) ? self::SUCCESS : self::FAILURE;
    }

    /** The weaker side's answer: the book's plan against each shape, against its other plans. */
    private function underdog(MasterClub $strong): bool
    {
        $weak = $this->option('underdog') ? MasterClub::where('name', $this->option('underdog'))->firstOrFail()
            : MasterClub::where('league_name', $strong->league_name)->orderBy('strength_cp')->firstOrFail();
        $need = (int) config('game.engine.counter_edge_min_pts');
        $book = collect(TacticsBook::build(config('game.engine'))['shapes'])->keyBy('shape');
        $rows = [];
        $ok = true;
        foreach (self::SHAPES as $shape => $tactics) {
            $points = [];
            foreach (['counter', 'long', 'passing', 'wings', 'shots'] as $plan) {
                $s = Batch::summary(Batch::run($weak, $strong, (int) $this->option('n'), ['venue' => 'neutral'],
                    ['home' => ['tactics' => ['plan' => $plan]], 'away' => ['tactics' => $tactics]]));
                $points[$plan] = $s['home_win_%'] + $s['draw_%'] / 2;
            }
            $named = $book[$shape]['beaten_by'];
            $answer = $points[$named[0]];
            $others = array_diff_key($points, array_flip($named));
            $ordinary = round(array_sum($others) / max(1, count($others)), 1);
            $edge = round($answer - $ordinary, 1);
            $ok = $ok && $edge >= $need;
            $rows[] = [$shape, $named[0], $answer, $ordinary, $edge];
        }
        $this->line("Underdog: {$weak->name} ({$weak->strength_cp}) against {$strong->name} ({$strong->strength_cp})");
        $this->table(['their shape', 'book plan', 'points %', 'other plans %', 'edge'], $rows);
        $ok ? $this->info("The book's plan gives the underdog {$need}+ points everywhere.")
            : $this->error("The book's plan gives the underdog less than {$need} points somewhere.");

        return $ok;
    }
}
