<?php

namespace App\Console\Commands;

use App\Http\Controllers\Api\DataController;
use App\Tournament\NationSquad;
use Illuminate\Console\Command;

/**
 * [Sprint 29] The national teams, made from the players' nationalities: every country with enough players (and a
 * goalkeeper) is a master club of source "nation", with its strength from its best players. Run after every import
 * (deploy/docker/start.sh); it adds the new countries and updates the strength of the others, and touches nothing else.
 */
class DataNations extends Command
{
    protected $signature = 'data:nations';

    protected $description = 'Make (or refresh) the national teams from the players\' nationalities';

    public function handle(): int
    {
        $version = DataController::version();
        if ($version === '') {
            $this->warn('No data yet: run data:import first.');

            return self::SUCCESS;
        }
        [$made, $updated] = NationSquad::sync($version);
        $this->info("National teams: {$made} new, {$updated} updated (version {$version}).");

        return self::SUCCESS;
    }
}
