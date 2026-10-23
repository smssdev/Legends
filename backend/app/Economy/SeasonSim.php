<?php

namespace App\Economy;

use App\League\RoundRobin;

/**
 * A season of club money without the database [Sprint 23 B5, sim:economy]: the league's clubs, home and away,
 * each match's score from $play, and the same Money rules the game applies (gate, wages, bonus, the debt
 * count and its forced sales, the league prizes). Two scenarios ride on it: a spendthrift coach who spends
 * every coin on players at once, and two colluding accounts moving money between their clubs by an
 * overpriced trade, as far as the pair cap lets them.
 *
 * $clubs: [id => ['name', 'strength', 'players' => list<value>]], strongest first.
 */
class SeasonSim
{
    public function __construct(private Money $money, private array $cfg) {}

    /** @param callable(int $home, int $away, int $round): array{home: int, away: int} $play */
    public function run(array $clubs, int $budget, callable $play, array $scenario = []): array
    {
        $ids = array_keys($clubs);
        $rounds = RoundRobin::rounds($ids);
        $nRounds = count($rounds);
        $scale = intdiv(array_sum(array_map(fn ($c) => array_sum($c['players']), $clubs)), count($clubs));
        $strengths = array_column($clubs, 'strength');
        [$min, $max] = [min($strengths), max($strengths)];
        $book = [];
        foreach ($clubs as $id => $c) {
            rsort($clubs[$id]['players']);
            $book[$id] = ['balance' => $budget, 'low' => $budget, 'debt' => 0, 'sold' => 0, 'bought' => 0, 'pts' => 0, 'gd' => 0, 'income' => 0, 'wages' => 0];
        }
        $spender = $scenario['spender'] ?? null;
        $colluders = $scenario['colluders'] ?? null;
        $moved = 0;
        if ($colluders) {
            // One overpriced trade: the most the pair cap lets pass from one club to the other this season.
            [$from, $to] = $colluders;
            $moved = intdiv($budget * $this->cfg['pair_net_transfer_cap_bp'], 10000);
            $book[$from]['balance'] -= $moved;
            $book[$to]['balance'] += $moved;
        }

        $trader = $scenario['trader'] ?? null;
        $half = intdiv($nRounds, 2);
        foreach ($rounds as $r => $round) {
            // The trader buys half his money's worth from the pool at the start of each window, trains him all
            // the way (his value rises; the pool ignores it), and sells him back to the pool before the next one.
            if ($trader && ($r === 0 || $r === $half)) {
                if ($r === $half) {
                    $this->traderSells($trader, $clubs, $book);
                }
                $v = intdiv(max(0, $book[$trader]['balance']), 2);
                $clubs[$trader]['players'][] = $v;
                $clubs[$trader]['traded'] = $v;
                $book[$trader]['balance'] -= $v;
                $book[$trader]['bought'] += $v;
            }
            foreach ($round['matches'] as [$home, $away]) {
                $score = $play($home, $away, $r + 1);
                $won = $score['home'] > $score['away'];
                $gate = $this->money->tickets($scale, $nRounds, $this->money->attendance($clubs[$home]['strength'], $min, $max));
                foreach (array_keys($this->cfg['sectors']) as $sector) {
                    $gate += $this->money->sponsor($scale, $nRounds, $sector, $scenario['offer'] ?? 'steady', $won);
                }
                $book[$home]['balance'] += $gate;
                $book[$home]['income'] += $gate;
                foreach ([[$home, $score['home'], $score['away']], [$away, $score['away'], $score['home']]] as [$id, $for, $against]) {
                    $wages = $this->money->wages(array_sum($clubs[$id]['players']), $nRounds);
                    $bonus = $this->money->resultBonus($scale, $for, $against);
                    // Training: every coach keeps his four slots busy all season [PLAN 2.8, Sprint 27].
                    $wages += intdiv($scale * (int) ($this->cfg['training_bp'] ?? 0), 10000 * $nRounds);
                    $book[$id]['balance'] += $bonus - $wages;
                    $book[$id]['income'] += $bonus;
                    $book[$id]['wages'] += $wages;
                    $book[$id]['pts'] += $for > $against ? 3 : ($for === $against ? 1 : 0);
                    $book[$id]['gd'] += $for - $against;
                    $this->debt($id, $clubs, $book);
                    $book[$id]['low'] = min($book[$id]['low'], $book[$id]['balance']);
                }
            }
            // The spendthrift buys a player with every coin he has, after every round.
            if ($spender && $book[$spender]['balance'] > 0) {
                $clubs[$spender]['players'][] = $book[$spender]['balance'];
                rsort($clubs[$spender]['players']);
                $book[$spender]['bought'] += $book[$spender]['balance'];
                $book[$spender]['balance'] = 0;
            }
        }

        if ($trader) {
            $this->traderSells($trader, $clubs, $book);
        }
        $order = $ids;
        usort($order, fn ($a, $b) => [$book[$b]['pts'], $book[$b]['gd'], $clubs[$b]['strength']] <=> [$book[$a]['pts'], $book[$a]['gd'], $clubs[$a]['strength']]);
        foreach ($order as $i => $id) {
            $prize = $this->money->leaguePrize($scale, $i + 1);
            $book[$id]['balance'] += $prize;
            $book[$id]['income'] += $prize;
            $book[$id]['place'] = $i + 1;
        }

        return ['scale' => $scale, 'rounds' => $nRounds, 'budget' => $budget, 'moved' => $moved, 'clubs' => $book,
            'squad' => array_map(fn ($c) => array_sum($c['players']), $clubs), 'size' => array_map(fn ($c) => count($c['players']), $clubs)];
    }

    /** The trader's player goes back to the pool: 70% of his base value, whatever his training added. */
    private function traderSells(int $id, array &$clubs, array &$book): void
    {
        $v = $clubs[$id]['traded'] ?? null;
        if ($v === null) {
            return;
        }
        $at = array_search($v, $clubs[$id]['players'], true);
        if ($at !== false) {
            array_splice($clubs[$id]['players'], $at, 1);
            $book[$id]['balance'] += $this->money->poolPays($v);
            $book[$id]['traded'] = ($book[$id]['traded'] ?? 0) + $this->money->poolPays($v) - $v;
        }
        unset($clubs[$id]['traded']);
    }

    /** As Economy: below zero for the limit of league rounds, the dearest players go to the pool. */
    private function debt(int $id, array &$clubs, array &$book): void
    {
        if ($book[$id]['balance'] >= 0) {
            $book[$id]['debt'] = 0;

            return;
        }
        if (++$book[$id]['debt'] < $this->cfg['debt_rounds_before_forced_sale']) {
            return;
        }
        while ($book[$id]['balance'] < 0 && count($clubs[$id]['players']) > $this->cfg['min_squad']) {
            $value = array_shift($clubs[$id]['players']);
            $book[$id]['balance'] += $this->money->poolPays($value);
            $book[$id]['sold']++;
        }
        $book[$id]['debt'] = 0;
    }

    /** The season in numbers, against the targets: no mass bankruptcy, no clear inflation. */
    public static function summary(array $season, array $targets): array
    {
        $clubs = $season['clubs'];
        $ends = array_column($clubs, 'balance');
        sort($ends);
        $n = count($ends);
        $broke = count(array_filter($ends, fn ($b) => $b < 0));
        $start = $season['budget'] * $n;
        $out = [
            'clubs' => $n,
            'broke_%' => round(100 * $broke / max(1, $n), 1),
            'forced_sales' => array_sum(array_column($clubs, 'sold')),
            'median_end_ratio' => round($ends[intdiv($n, 2)] / max(1, $season['budget']), 2),
            'money_growth' => round(array_sum($ends) / max(1, $start), 2),
            'richest_ratio' => round(end($ends) / max(1, $season['budget']), 2),
            'poorest_ratio' => round($ends[0] / max(1, $season['budget']), 2),
        ];
        $out['ok'] = $out['broke_%'] <= $targets['broke_%_max']
            && $out['median_end_ratio'] >= $targets['median_end_ratio'][0] && $out['median_end_ratio'] <= $targets['median_end_ratio'][1]
            && $out['money_growth'] <= $targets['money_growth_max'];

        return $out;
    }
}
