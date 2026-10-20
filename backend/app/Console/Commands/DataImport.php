<?php

namespace App\Console\Commands;

use App\Data\ClubIdentity;
use App\Data\PlayerValuation;
use App\Data\Potential;
use App\Support\GameClock;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use RuntimeException;

/**
 * Imports the EA FC 26 files into master_clubs and master_players
 * (docs/PLAN.md 2.6, data/ea-fc26/README.md). Re-running the same version
 * replaces it, so the command is safe to repeat.
 */
class DataImport extends Command
{
    protected $signature = 'data:import
        {--data-version=2026 : Version label stored on every row}
        {--path= : Folder with the CSV files (default: ../data/ea-fc26)}';

    protected $description = 'Import real clubs and players (with attributes) from the EA FC 26 files';

    /** South American cup entries are tournaments, not leagues (README). */
    private const SKIPPED_LEAGUES = ['Libertadores', 'Sudamericana'];

    private const MIN_SQUAD = 18;

    private const LINES = [
        'GK' => 'gk',
        'CB' => 'def', 'RB' => 'def', 'LB' => 'def',
        'CDM' => 'mid', 'CM' => 'mid', 'CAM' => 'mid', 'LM' => 'mid', 'RM' => 'mid',
        'ST' => 'att', 'LW' => 'att', 'RW' => 'att',
    ];

    private PlayerValuation $valuation;

    public function handle(): int
    {
        $this->valuation = PlayerValuation::fromConfig();
        $version = (string) $this->option('data-version');
        $path = $this->option('path') ?: base_path('../data/ea-fc26');

        $clubs = [];
        $rows = 0;
        foreach (['ea_fc26_outfield.csv', 'ea_fc26_goalkeepers.csv'] as $file) {
            foreach ($this->rows("$path/$file") as $row) {
                $rows++;
                if (in_array($row['leagueName'], self::SKIPPED_LEAGUES, true)) {
                    continue;
                }
                $clubs[$row['team']]['league'] = $row['leagueName'];
                $clubs[$row['team']]['players'][] = $this->player($row);
            }
        }

        $kept = array_filter($clubs, fn ($club) => count($club['players']) >= self::MIN_SQUAD
            && in_array('gk', array_column($club['players'], 'line'), true));

        DB::transaction(function () use ($kept, $version) {
            DB::table('master_clubs')->where('data_version', $version)->delete();
            $now = GameClock::now();

            foreach ($kept as $name => $club) {
                $overalls = array_column($club['players'], 'overall');
                rsort($overalls);
                $best = array_slice($overalls, 0, self::MIN_SQUAD);
                [$primary, $secondary] = ClubIdentity::colors($name);

                $clubId = DB::table('master_clubs')->insertGetId([
                    'data_version' => $version,
                    'name' => $name,
                    'code' => ClubIdentity::code($name),
                    'league_name' => $club['league'],
                    'strength_cp' => intdiv(array_sum($best) * 100, count($best)),
                    'color_primary' => $primary,
                    'color_secondary' => $secondary,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);

                $players = array_map(fn ($p) => $p + [
                    'data_version' => $version,
                    'master_club_id' => $clubId,
                    'created_at' => $now,
                    'updated_at' => $now,
                ], $club['players']);

                foreach (array_chunk($players, 100) as $chunk) {
                    DB::table('master_players')->insert($chunk);
                }
            }
        });

        $players = array_sum(array_map(fn ($c) => count($c['players']), $kept));
        $this->info(sprintf('Imported %d clubs and %d players (version %s) from %d rows; skipped %d clubs.',
            count($kept), $players, $version, $rows, count($clubs) - count($kept)));

        return self::SUCCESS;
    }

    /** Streams a CSV file as associative rows. */
    private function rows(string $file): \Generator
    {
        $handle = @fopen($file, 'r');
        if ($handle === false) {
            throw new RuntimeException("Cannot read $file");
        }

        $header = fgetcsv($handle, escape: '');
        while (($values = fgetcsv($handle, escape: '')) !== false) {
            if (count($values) === count($header)) {
                yield array_combine($header, $values);
            }
        }
        fclose($handle);
    }

    private function player(array $r): array
    {
        $int = fn (string $key) => isset($r[$key]) && $r[$key] !== '' ? (int) $r[$key] : null;
        $name = trim($r['commonName']) !== '' ? $r['commonName'] : trim($r['firstName'].' '.$r['lastName']);

        return [
            'external_id' => (int) $r['id'],
            'name' => $name,
            'position' => $r['position'],
            'line' => self::LINES[$r['position']] ?? 'mid',
            'alt_positions' => $r['alternatePositions'] ?: null,
            'age' => (int) $r['age'],
            'nationality' => $r['nationality'] ?: null,
            'preferred_foot' => $r['preferredFoot'] ?: null,
            'overall' => (int) $r['overallRating'],
            'potential' => $potential = Potential::for((int) $r['overallRating'], (int) $r['age']),
            'value' => $this->valuation->value((int) $r['overallRating'], (int) $r['age'], self::LINES[$r['position']] ?? 'mid', $potential),
            'pac' => $int('pac'), 'sho' => $int('sho'), 'pas' => $int('pas'),
            'dri' => $int('dri'), 'def' => $int('def'), 'phy' => $int('phy'),
            'gk_diving' => $int('gkDiving'), 'gk_handling' => $int('gkHandling'),
            'gk_kicking' => $int('gkKicking'), 'gk_positioning' => $int('gkPositioning'),
            'gk_reflexes' => $int('gkReflexes'),
            'penalties' => $int('penalties'), 'free_kick' => $int('freeKickAccuracy'),
            'crossing' => $int('crossing'), 'heading' => $int('headingAccuracy'),
            'stamina' => $int('stamina'), 'aggression' => $int('aggression'),
        ];
    }
}
