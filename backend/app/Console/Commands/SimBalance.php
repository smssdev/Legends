<?php

namespace App\Console\Commands;

use App\Models\MasterClub;
use App\Simulator\Batch;
use App\Simulator\MatchFactory;
use Illuminate\Console\Command;

/**
 * A whole league against the calibration targets (docs/ENGINE.md 9.1): every
 * club plays every other home and away, season after season with new seeds,
 * then the strongest club meets one 18 points weaker. Each target allows two
 * standard errors of the sample, so a short run on a PR and the 5000-match
 * nightly run use the same table. Fails when a number is outside.
 */
class SimBalance extends Command
{
    protected $signature = 'sim:balance {--n=5000 : League matches} {--favourite=1000 : Favourite matches}
        {--league= : League name (default from config)} {--seed=1} {--report= : Write the result as JSON to this file} {--json}';

    protected $description = 'League statistics against the calibration targets';

    public function handle(): int
    {
        $cfg = config('game.balance');
        $league = $this->option('league') ?: $cfg['league'];
        $clubs = MasterClub::where('league_name', $league)->orderByDesc('strength_cp')->orderBy('id')->get();
        if ($clubs->count() < 2) {
            $this->error("No league named {$league}.");

            return self::FAILURE;
        }

        $seed = (int) $this->option('seed');
        $bases = [];
        foreach ($clubs as $home) {
            foreach ($clubs as $away) {
                if ($home->id !== $away->id) {
                    $bases[] = MatchFactory::make($home, $away, ['seed' => 0]);
                }
            }
        }
        $raw = Batch::fixtures($bases, (int) $this->option('n'), $seed);
        $summary = Batch::summary($raw);

        // The favourite: the league's strongest club against the club nearest to it minus the gap, venues alternating.
        $top = $clubs->first();
        $gap = (int) $cfg['favourite_gap_points'] * 100;
        $weak = MasterClub::where('id', '!=', $top->id)->orderByRaw('abs(strength_cp - ?)', [$top->strength_cp - $gap])->orderBy('id')->first();
        $fn = (int) $this->option('favourite');
        $favWins = $this->favouriteWins($top, $weak, $fn, $seed + 1_000_000);
        $summary['favourite_win_%'] = round(100 * $favWins / max(1, $fn), 1);

        $rows = [];
        $failed = 0;
        foreach ($cfg['targets'] as $metric => [$min, $max]) {
            $value = $summary[$metric];
            $slack = $this->slack($metric, $value, $raw['n'], $raw['goals'], $fn);
            $ok = $value >= $min - $slack && $value <= $max + $slack;
            $failed += $ok ? 0 : 1;
            $rows[] = ['metric' => $metric, 'value' => $value, 'target' => "{$min} – {$max}", 'slack' => round($slack, 2), 'ok' => $ok];
        }
        $result = ['league' => $league, 'matches' => $raw['n'], 'favourite' => "{$top->name} vs {$weak->name}",
            'favourite_gap' => round(($top->strength_cp - $weak->strength_cp) / 100, 1), 'favourite_matches' => $fn,
            'passed' => $failed === 0, 'targets' => $rows, 'summary' => $summary];

        if ($this->option('report')) {
            @mkdir(dirname($this->option('report')), 0775, true);
            file_put_contents($this->option('report'), json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
        }
        if ($this->option('json')) {
            $this->line(json_encode($result));
        } else {
            $this->info(sprintf('%s: %d matches, favourite %s (gap %.1f) %d matches', $league, $raw['n'], $result['favourite'],
                $result['favourite_gap'], $fn));
            $this->table(['metric', 'value', 'target', '± sample', ''], array_map(fn ($r) => [$r['metric'], $r['value'], $r['target'], $r['slack'], $r['ok'] ? 'ok' : 'OUT'], $rows));
        }

        if ($failed) {
            $this->error("{$failed} number(s) outside their targets.");

            return self::FAILURE;
        }
        $this->info('All numbers inside their targets.');

        return self::SUCCESS;
    }

    /** Wins of the stronger club over the alternating fixtures (it is home in the even ones). */
    private function favouriteWins(MasterClub $top, MasterClub $weak, int $n, int $seedFrom): int
    {
        $home = Batch::fixtures([MatchFactory::make($top, $weak, ['seed' => 0])], intdiv($n + 1, 2), $seedFrom);
        $away = Batch::fixtures([MatchFactory::make($weak, $top, ['seed' => 0])], intdiv($n, 2), $seedFrom + $n);

        return $home['home_win'] + $away['away_win'];
    }

    /** Two standard errors of the sample: binomial for shares, Poisson for counts. */
    private function slack(string $metric, float $value, int $n, int $goals, int $favourites): float
    {
        $share = fn (float $pct, int $of) => 200 * sqrt(max(0.0, $pct / 100 * (1 - $pct / 100)) / max(1, $of));

        return match (true) {
            $metric === 'favourite_win_%' => $share($value, $favourites),
            $metric === 'late_goals_%' => $share($value, $goals),
            str_ends_with($metric, '_%') => $share($value, $n),
            str_ends_with($metric, '/team') => 2 * sqrt($value / (2 * $n)),
            default => 2 * sqrt($value / $n),
        };
    }
}
