<?php

namespace App\Console\Commands;

use App\Database\Copier;
use Illuminate\Console\Command;
use Throwable;

/**
 * The league from Render's SQLite into Supabase [X43], once: start.sh brings the game back from B2 as it was saved,
 * migrates Supabase, then runs this. Supabase that already holds a game is never written over (it says so and
 * stops), so a restart after the move changes nothing. All in one transaction: a failure leaves Supabase empty,
 * and the SQLite file and B2 are only read, so the move can be tried again.
 */
class DbToSupabase extends Command
{
    protected $signature = 'db:to-supabase {--from=database/legends.sqlite : The SQLite file of the game} {--check : Only say whether Supabase holds the game (exit 0) or not (exit 1)}';

    protected $description = 'Copy the game from its SQLite file into the PostgreSQL database (Supabase), once';

    public function handle(): int
    {
        $to = config('database.default');
        if (config("database.connections.$to.driver") !== 'pgsql') {
            $this->error('DB_CONNECTION is not pgsql: nothing to move.');

            return self::FAILURE;
        }
        if ($this->option('check')) {
            return Copier::hasGame($to) ? self::SUCCESS : self::FAILURE;
        }
        if (Copier::hasGame($to)) {
            $this->info('Supabase already holds the game: nothing copied.');

            return self::SUCCESS;
        }
        $file = $this->option('from');
        $file = str_starts_with($file, '/') ? $file : base_path($file);
        if (! is_file($file)) {
            $this->info("No SQLite game at {$file}: Supabase starts empty.");

            return self::SUCCESS;
        }
        config(['database.connections.legacy' => ['driver' => 'sqlite', 'database' => $file, 'prefix' => '', 'foreign_key_constraints' => false]]);
        try {
            $counts = Copier::copy('legacy', $to);
        } catch (Throwable $e) {
            $this->error('The move failed, Supabase is left empty: '.$e->getMessage());

            return self::FAILURE;
        }
        $this->info('The game is in Supabase: '.array_sum($counts).' rows in '.count(array_filter($counts)).' tables.');
        foreach (['users', 'leagues', 'clubs', 'players', 'matches'] as $t) {
            $this->line("  {$t}: ".($counts[$t] ?? 0));
        }

        return self::SUCCESS;
    }
}
