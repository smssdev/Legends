<?php

namespace App\Console\Commands;

use App\Economy\Money;
use App\Economy\SeasonSim;
use App\Models\MasterClub;
use App\Simulator\MatchFactory;
use App\Simulator\Runner;
use Illuminate\Console\Command;

/**
 * A season of club money [PLAN 2.7, Sprint 23 B5]: a real league's clubs play home and away on the engine, and
 * the economy's rules run on every match. Three runs: everyone sensible; a spendthrift coach who spends every
 * coin on players at once; and two colluding accounts moving the most the pair cap allows. The report says
 * whether the season ends without mass bankruptcy or clear inflation (config game.economy.sim_targets).
 */
class SimEconomy extends Command
{
    protected $signature = 'sim:economy {--league=Premier League} {--budget= : Starting budget (default from config)} {--seed=1} {--report= : Write the result as JSON to this file}';

    protected $description = 'A season of club money on the engine, against the economy targets';

    public function handle(): int
    {
        $cfg = config('game.economy');
        $cfg['training_bp'] = (int) config('game.training.slots') * (int) config('game.training.cost_bp_per_season');
        $masters = MasterClub::where('league_name', $this->option('league'))->orderByDesc('strength_cp')->orderBy('id')->get();
        if ($masters->count() < 4) {
            $this->error('No league named '.$this->option('league').'.');

            return self::FAILURE;
        }
        $budget = (int) ($this->option('budget') ?: $cfg['starting_budget']);
        $clubs = $masters->mapWithKeys(fn ($c) => [$c->id => ['name' => $c->name, 'strength' => (int) $c->strength_cp,
            'players' => $c->players()->pluck('value')->map(fn ($v) => (int) $v)->all()]])->all();

        // Each pairing's score is played once on the engine and kept, so the three runs see the same season.
        $seed = (int) $this->option('seed');
        $scores = [];
        $play = function (int $home, int $away, int $round) use (&$scores, $masters, $seed) {
            return $scores["{$home}:{$away}"] ??= (function () use ($home, $away, $round, $masters, $seed) {
                $state = MatchFactory::make($masters->firstWhere('id', $home), $masters->firstWhere('id', $away), ['seed' => $seed * 100_000 + $home * 300 + $away + $round]);
                [$end] = Runner::toEnd($state);

                return $end['score'];
            })();
        };

        $sim = new SeasonSim(Money::fromConfig(), $cfg);
        $ids = array_keys($clubs);
        $median = $ids[intdiv(count($ids), 2)];
        $runs = [
            'normal' => $sim->run($clubs, $budget, $play),
            'spender' => $sim->run($clubs, $budget, $play, ['spender' => $median]),
            'colluders' => $sim->run($clubs, $budget, $play, ['colluders' => [$ids[count($ids) - 1], $ids[count($ids) - 2]]]),
            'trader' => $sim->run($clubs, $budget, $play, ['trader' => $median]),
        ];
        $summary = SeasonSim::summary($runs['normal'], $cfg['sim_targets']);

        $n = $runs['normal'];
        $this->info(sprintf('%s: %d clubs, %d rounds, budget %s, scale %s', $this->option('league'), count($clubs), $n['rounds'], number_format($budget), number_format($n['scale'])));
        $rows = [];
        foreach ($n['clubs'] as $id => $b) {
            $rows[] = [$b['place'], $clubs[$id]['name'], number_format($n['squad'][$id]), number_format($b['income']), number_format(-$b['wages']),
                number_format($b['balance']), number_format($b['low']), $b['sold']];
        }
        usort($rows, fn ($a, $b) => $a[0] <=> $b[0]);
        $this->table(['#', 'النادي', 'قيمة التشكيلة', 'الدخل', 'الرواتب', 'الرصيد في النهاية', 'أقل رصيد', 'بيع إجباري'], $rows);
        $this->table(['المقياس', 'القيمة'], collect($summary)->except('ok')->map(fn ($v, $k) => [$k, $v])->values()->all());

        $s = $runs['spender']['clubs'][$median];
        $this->line(sprintf('المبذّر (%s): اشترى بـ %s، وبيع له إجبارياً %d لاعبين، وأنهى بـ %s (الوسيط العاقل %s).',
            $clubs[$median]['name'], number_format($s['bought']), $s['sold'], number_format($s['balance']), number_format($n['clubs'][$median]['balance'])));
        [$from, $to] = [$ids[count($ids) - 1], $ids[count($ids) - 2]];
        $c = $runs['colluders']['clubs'];
        $this->line(sprintf('المتواطئان: انتقل %s فقط (سقف الزوج)، فأنهى %s بـ %s بدل %s.',
            number_format($runs['colluders']['moved']), $clubs[$to]['name'], number_format($c[$to]['balance']), number_format($n['clubs'][$to]['balance'])));

        $t = $runs['trader']['clubs'][$median];
        $this->line(sprintf('دورة «اشترِ، درّب، بِع للمجموعة» (%s، مرتين في الموسم): خسر في البيع %s، وأنهى بـ %s بدل %s.',
            $clubs[$median]['name'], number_format(-($t['traded'] ?? 0)), number_format($t['balance']), number_format($n['clubs'][$median]['balance'])));
        $summary['trade_cycle_profit'] = ($t['traded'] ?? 0);
        $summary['ok'] = $summary['ok'] && $summary['trade_cycle_profit'] < 0;

        if ($this->option('report')) {
            @mkdir(dirname($this->option('report')), 0775, true);
            file_put_contents($this->option('report'), json_encode(['summary' => $summary, 'runs' => $runs], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
        }
        $this->line($summary['ok'] ? '<info>داخل الأهداف.</info>' : '<error>خارج الأهداف.</error>');

        return $summary['ok'] ? self::SUCCESS : self::FAILURE;
    }
}
