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
 * (docs/PLAN.md 2.6, data/ea-fc26/README.md), and the Arab leagues EA does not have (data/arab, X34).
 * Re-running the same version replaces it, so the command is safe to repeat on an empty game.
 *
 * With --add it only adds the clubs this version does not have yet, and touches nothing that is there: a running
 * league's players point at their master rows, so replacing those would cut it from them. That is how new data
 * reaches the live server (deploy/render/start.sh runs it after the migrations).
 */
class DataImport extends Command
{
    protected $signature = 'data:import
        {--data-version=2026 : Version label stored on every row}
        {--path= : Folder with the CSV files (default: ../data/ea-fc26)}
        {--arab= : Folder with the Arab leagues file (default: ../data/arab)}
        {--add : Only add the clubs that are not there yet, never replace or remove}';

    protected $description = 'Import real clubs and players (with attributes) from the EA FC 26 files';

    /**
     * South American cup entries are tournaments, not leagues (README). EA's UAE entry is one club; the full UAE Pro
     * League comes from data/arab [X34].
     */
    private const SKIPPED_LEAGUES = ['Libertadores', 'Sudamericana', 'United Emirates League'];

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

        // The Arab file next to the EA files by default; a given --path (the tests' fixtures) reads only what it names.
        $arab = $this->option('arab') ?: ($this->option('path') ? '' : base_path('../data/arab'));
        $files = ["$path/ea_fc26_outfield.csv", "$path/ea_fc26_goalkeepers.csv"];
        if ($arab !== '' && is_file("$arab/arab_players.csv")) {
            $files[] = "$arab/arab_players.csv";
        }

        $clubs = [];
        $rows = 0;
        foreach ($files as $file) {
            foreach ($this->rows($file) as $row) {
                $rows++;
                if (in_array($row['leagueName'], self::SKIPPED_LEAGUES, true)) {
                    continue;
                }
                $clubs[$row['team']]['league'] = $row['leagueName'];
                // The Arab file carries each club's kit colours from Wikipedia [X34].
                if (($row['clubPrimary'] ?? '') !== '') {
                    $clubs[$row['team']]['colors'] = [$row['clubPrimary'], $row['clubSecondary'] ?: '#FFFFFF'];
                }
                $clubs[$row['team']]['players'][] = $this->player($row);
            }
        }

        $kept = array_filter($clubs, fn ($club) => count($club['players']) >= self::MIN_SQUAD
            && in_array('gk', array_column($club['players'], 'line'), true));

        $add = (bool) $this->option('add');
        if ($add) {
            $there = DB::table('master_clubs')->where('data_version', $version)->pluck('name')->flip()->all();
            $kept = array_diff_key($kept, $there);
        }

        DB::transaction(function () use ($kept, $version, $add) {
            if (! $add) {
                DB::table('master_clubs')->where('data_version', $version)->delete();
            }
            $now = GameClock::now();

            foreach ($kept as $name => $club) {
                $overalls = array_column($club['players'], 'overall');
                rsort($overalls);
                $best = array_slice($overalls, 0, self::MIN_SQUAD);
                [$primary, $secondary] = $club['colors'] ?? ClubIdentity::colors($name);

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
        $this->info($add
            ? sprintf('Added %d new clubs and %d players (version %s); the clubs already there were left as they are.', count($kept), $players, $version)
            : sprintf('Imported %d clubs and %d players (version %s) from %d rows; skipped %d clubs.',
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
