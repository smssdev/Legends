<?php

namespace App\Console\Commands;

use App\Database\Copier;
use App\Support\GameClock;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Process;

/**
 * Copies the three SQLite files (data, cache, queue) into database/backups/<time>/
 * with VACUUM INTO, which is safe while the game is running (WAL mode), and keeps
 * the newest --keep copies. Runs daily from the scheduler [PLAN 2.19]. With BACKUP_RCLONE_REMOTE set (an rclone
 * remote to Google Drive, e.g. "gdrive:LegendsBackups"), the copy also goes there, off this machine [Sprint 37].
 * On PostgreSQL (Supabase, X43) the game is written as one file of rows instead (legends.jsonl.gz, App\Database\Copier),
 * which db:restore brings into an empty database.
 */
class DbBackup extends Command
{
    protected $signature = 'db:backup {--keep=14 : How many backups to keep}';

    protected $description = 'Back up the databases';

    public function handle(): int
    {
        $root = base_path('database/backups');
        $dir = $root.'/'.GameClock::now()->format('Y-m-d_His');
        File::ensureDirectoryExists($dir);

        if (config('database.connections.'.config('database.default').'.driver') === 'pgsql') {
            Copier::dump(config('database.default'), $dir.'/legends.jsonl.gz');
        }
        foreach (['sqlite', 'cache_db', 'queue_db'] as $connection) {
            if (config("database.connections.$connection.driver") !== 'sqlite' || ($connection === 'sqlite' && config('database.default') !== 'sqlite')) {
                continue;
            }
            $source = config("database.connections.$connection.database");
            if (! is_file($source)) {
                continue;
            }
            // A connection of its own: VACUUM INTO cannot run inside an open transaction.
            $pdo = new \PDO('sqlite:'.$source);
            $pdo->exec('PRAGMA busy_timeout = 10000');
            File::delete($dir.'/'.basename($source));
            $pdo->prepare('VACUUM INTO ?')->execute([$dir.'/'.basename($source)]);
        }

        $all = collect(File::directories($root))->sort()->values();
        foreach ($all->slice(0, max(0, $all->count() - (int) $this->option('keep'))) as $old) {
            File::deleteDirectory($old);
        }

        $this->info("نسخة احتياطية في $dir");

        $remote = config('game.backup.rclone_remote');
        if ($remote) {
            $copy = Process::timeout(1800)->run(['rclone', 'copy', $dir, rtrim($remote, '/').'/'.basename($dir)]);
            if (! $copy->successful()) {
                $this->error('لم تُرفع النسخة إلى Google Drive: '.trim($copy->errorOutput()));

                return self::FAILURE;
            }
            // Drive keeps a month.
            Process::timeout(600)->run(['rclone', 'delete', $remote, '--min-age', '30d', '--rmdirs']);
            $this->info("ورُفعت إلى {$remote}");
        }

        return self::SUCCESS;
    }
}
