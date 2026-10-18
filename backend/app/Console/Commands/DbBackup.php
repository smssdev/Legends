<?php

namespace App\Console\Commands;

use App\Support\GameClock;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;

/**
 * Copies the three SQLite files (data, cache, queue) into database/backups/<time>/
 * with VACUUM INTO, which is safe while the game is running (WAL mode), and keeps
 * the newest --keep copies. Runs daily from the scheduler [PLAN 2.19].
 */
class DbBackup extends Command
{
    protected $signature = 'db:backup {--keep=14 : How many backups to keep}';

    protected $description = 'Back up the SQLite databases';

    public function handle(): int
    {
        $root = base_path('database/backups');
        $dir = $root.'/'.GameClock::now()->format('Y-m-d_His');
        File::ensureDirectoryExists($dir);

        foreach (['sqlite', 'cache_db', 'queue_db'] as $connection) {
            $source = config("database.connections.$connection.database");
            if (! is_file($source)) {
                continue;
            }
            // A connection of its own: VACUUM INTO cannot run inside an open transaction.
            $pdo = new \PDO('sqlite:'.$source);
            $pdo->exec('PRAGMA busy_timeout = 10000');
            $pdo->prepare('VACUUM INTO ?')->execute([$dir.'/'.basename($source)]);
        }

        $all = collect(File::directories($root))->sort()->values();
        foreach ($all->slice(0, max(0, $all->count() - (int) $this->option('keep'))) as $old) {
            File::deleteDirectory($old);
        }

        $this->info("نسخة احتياطية في $dir");

        return self::SUCCESS;
    }
}
