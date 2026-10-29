<?php

namespace App\Console\Commands;

use App\Data\PlayerValuation;
use App\Economy\Money;
use App\Economy\SeasonSim;
use App\Models\MasterClub;
use App\Simulator\MatchFactory;
use App\Simulator\Runner;
use App\Training\Gain;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * A season of club money [PLAN 2.7, Sprint 23 B5]: a real league's clubs play home and away on the engine, and
 * the economy's rules run on every match. Four runs: everyone sensible; a spendthrift coach who spends every
 * coin on players at once; two colluding accounts moving the most the pair cap allows; and a dealer making every
 * profit selling outside the league there is [Sprint 23], against what buying, training and selling would make uncapped. The report says
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
            'dealer' => $sim->run($clubs, $budget, $play, ['dealer' => $median]),
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

        // [Sprint 23] What buying young players, training them a season and selling them would make without the
        // profit room: the reason for it. Players of this league's level aged up to 21 with room to grow, one per slot.
        $gain = Gain::fromConfig();
        $valuation = PlayerValuation::fromConfig();
        $levels = collect($clubs)->flatMap(fn ($c) => $c['players']);
        $young = DB::table('master_players')->where('data_version', DB::table('master_players')->max('data_version'))->where('age', '<=', 21)
            ->whereColumn('potential', '>', 'overall')->whereBetween('value', [(int) $levels->min(), (int) $levels->max()])->orderBy('id')->limit(300)->get();
        $profits = $young->map(fn ($p) => $valuation->value((int) $p->overall + $gain->run((int) $p->overall, (int) $p->potential, (int) config('game.training.season_sessions'), "{$seed}:{$p->id}", 0, (int) $p->age),
            (int) $p->age, $p->line, (int) $p->potential) - $valuation->value((int) $p->overall, (int) $p->age, $p->line, (int) $p->potential));
        $summary['uncapped_trade_profit'] = $profits->isEmpty() ? 0 : intdiv((int) $profits->sum(), $profits->count()) * (int) config('game.training.slots');
        $this->line(sprintf('بلا سقف الربح: من يشتري %d لاعبين صغاراً ويدربهم موسماً ثم يبيعهم يربح نحو %s (دخل الموسم نحو %s).',
            (int) config('game.training.slots'), number_format($summary['uncapped_trade_profit']), number_format($n['clubs'][$median]['income'])));

        // [Sprint 23] Every profit selling outside (250%, buy-train-sell, the discounts): the profit room is the most it brings.
        $l = $runs['dealer']['clubs'][$median];
        $summary['dealer_ratio'] = round($l['balance'] / max(1, $n['clubs'][$median]['balance']), 2);
        $this->line(sprintf('التاجر (%s: يبيع بـ 250%%، ويشتري الصغار ويدربهم ويبيعهم، ويستغل الخصومات): ربحه %s على الأكثر، فأنهى بـ %s بدل %s (×%s، والحد ×%s).',
            $clubs[$median]['name'], number_format($l['premium']), number_format($l['balance']), number_format($n['clubs'][$median]['balance']),
            $summary['dealer_ratio'], $cfg['sim_targets']['money_growth_max']));
        $summary['ok'] = $summary['ok'] && $summary['dealer_ratio'] <= $cfg['sim_targets']['money_growth_max'];

        if ($this->option('report')) {
            @mkdir(dirname($this->option('report')), 0775, true);
            file_put_contents($this->option('report'), json_encode(['summary' => $summary, 'runs' => $runs], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
        }
        $this->line($summary['ok'] ? '<info>داخل الأهداف.</info>' : '<error>خارج الأهداف.</error>');

        return $summary['ok'] ? self::SUCCESS : self::FAILURE;
    }
}
