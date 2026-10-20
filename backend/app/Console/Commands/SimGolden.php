<?php

namespace App\Console\Commands;

use App\Models\MasterClub;
use App\Models\SimMatch;
use App\Simulator\Golden;
use App\Simulator\MatchFactory;
use App\Simulator\Simulator;
use Illuminate\Console\Command;

/**
 * The engine's golden recordings (docs/ENGINE.md 9): checks them, or with
 * --write records them again after an engine change, together with the
 * sample match in docs/api/samples/.
 */
class SimGolden extends Command
{
    protected $signature = 'sim:golden {--write : Record the golden matches and the sample again}';

    protected $description = 'Check or record the golden matches that must be identical on x86 and ARM';

    private const SAMPLE = ['Liverpool', 'Arsenal', 48213];

    public function handle(Simulator $sim): int
    {
        $path = base_path(Golden::FILE);
        if ($this->option('write')) {
            $snapshot = MatchFactory::snapshot();
            $matches = array_map(fn ($c) => Golden::play($c, $snapshot), Golden::CASES);
            @mkdir(dirname($path), 0775, true);
            file_put_contents($path, json_encode(['engine_version' => $snapshot['engine']['version'], 'snapshot' => $snapshot, 'matches' => $matches],
                JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE)."\n");
            $this->writeSample($sim);
            $this->info('Recorded '.count($matches).' golden matches and the sample.');

            return self::SUCCESS;
        }

        $golden = json_decode(file_get_contents($path), true);
        $failed = 0;
        foreach (Golden::CASES as $i => $case) {
            $now = Golden::play($case, $golden['snapshot']);
            $ok = $now === $golden['matches'][$i];
            $failed += $ok ? 0 : 1;
            $this->line(sprintf('%-6s seed %-6d %d-%d %s', $ok ? 'same' : 'DIFF', $case[0], $now['score']['home'], $now['score']['away'], $now['sha256']));
        }
        $this->line('Processor: '.php_uname('m'));

        return $failed ? self::FAILURE : self::SUCCESS;
    }

    /** The full sample match the event contract points to (docs/api/match-events.md). */
    private function writeSample(Simulator $sim): void
    {
        [$home, $away, $seed] = self::SAMPLE;
        $match = $sim->create(['home_id' => MasterClub::where('name', $home)->value('id'), 'away_id' => MasterClub::where('name', $away)->value('id'),
            'seed' => $seed, 'control' => ['home' => 'cpu', 'away' => 'cpu']]);
        $view = $sim->view($match);
        $ticks = $sim->advance($match, 200);
        $sample = ['match' => $view, 'ticks' => $ticks, 'report' => $sim->report($match->fresh())];
        file_put_contents(base_path('../docs/api/samples/'.strtolower("$home-$away-$seed").'.json'), json_encode($sample, JSON_UNESCAPED_UNICODE)."\n");
        SimMatch::whereKey($match->id)->delete();
    }
}
