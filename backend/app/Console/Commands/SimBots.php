<?php

namespace App\Console\Commands;

use App\League\Bot;
use App\Models\MasterClub;
use App\Simulator\Batch;
use Illuminate\Console\Command;

/**
 * The six bot personalities on the pitch [ENGINE 7, Sprint 32]: the same club with each personality's tactics
 * against itself as the neutral adaptive bot, on a neutral ground. Each personality must show in its numbers:
 * the hard side the most cards, the pressers the most balls won high and the most tired legs, the defenders the
 * freshest legs and more counters than the giants, and the giants more of the attacks than the defenders.
 */
class SimBots extends Command
{
    protected $signature = 'sim:bots {--club=Liverpool} {--n=200}';

    protected $description = 'Each bot personality in the match numbers';

    public function handle(): int
    {
        $club = MasterClub::where('name', $this->option('club'))->firstOrFail();
        $strength = (int) $club->strength_cp;
        $seen = ['public' => null, 'form' => []];
        $neutral = Bot::tactics('adaptive', $strength, $strength, $seen, 0);
        $rows = [];
        foreach (array_keys(config('game.bots.personalities')) as $p) {
            $s = Batch::summary(Batch::run($club, $club, (int) $this->option('n'), ['venue' => 'neutral'],
                ['home' => ['tactics' => Bot::tactics($p, $strength, $strength, $seen, 1)], 'away' => ['tactics' => $neutral]]));
            $rows[$p] = [
                'share' => round(100 * $s['attacks_home'] / max(0.01, $s['attacks_home'] + $s['attacks_away']), 1),
                'counters' => $s['counters_home'], 'presses' => $s['presses_won_home'], 'yellow' => $s['yellow_home'],
                'fitness' => $s['fitness_end_home_%'], 'points' => round($s['home_win_%'] + $s['draw_%'] / 2, 1),
            ];
        }
        $this->table(['الشخصية', 'نصيب الهجمات %', 'مرتدات', 'استعادة عالية', 'إنذارات', 'لياقة النهاية %', 'نقاط %'],
            array_map(fn ($p, $r) => [$p, ...array_values($r)], array_keys($rows), $rows));

        $top = fn ($k) => array_search(max(array_column($rows, $k)), array_column($rows, $k, null), true);
        $keys = array_keys($rows);
        $checks = [
            'الخشنون أكثر إنذارات' => $keys[$top('yellow')] === 'hard',
            'الضاغطون أكثر استعادة عالية' => $keys[$top('presses')] === 'pressers',
            'الضاغطون أتعب في النهاية' => $rows['pressers']['fitness'] === min(array_column($rows, 'fitness')),
            'المدافعون أنشط في النهاية' => $rows['defenders']['fitness'] === max(array_column($rows, 'fitness')),
            'الكبار يهاجمون أكثر من المدافعين' => $rows['giants']['share'] > $rows['defenders']['share'],
            'مرتدات المدافعين أكثر من الكبار' => $rows['defenders']['counters'] > $rows['giants']['counters'],
        ];
        $ok = true;
        foreach ($checks as $what => $pass) {
            $this->line(($pass ? 'ok   ' : 'FAIL ').$what);
            $ok = $ok && $pass;
        }

        return $ok ? self::SUCCESS : self::FAILURE;
    }
}
