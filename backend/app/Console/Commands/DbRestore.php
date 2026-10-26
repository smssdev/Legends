<?php

namespace App\Console\Commands;

use App\Database\Copier;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

/**
 * Puts a backup back [PLAN 2.19, Sprint 37]: a folder of db:backup (here, or downloaded from Google Drive), or a
 * database file Litestream restored ("litestream restore -o file.sqlite <replica>"). The game must be stopped
 * (update.ps1 stops it); the current files are kept beside, as *.before-restore.
 * On PostgreSQL (Supabase, X43): the rows of a backup (legends.jsonl.gz) into a database that holds no game yet (a
 * new Supabase project, migrated): a game there is never written over.
 */
class DbRestore extends Command
{
    protected $signature = 'db:restore {from : A backup folder name in database/backups, a folder path, or a .sqlite file} {--force : Do it without asking}';

    protected $description = 'Restore the databases from a backup';

    public function handle(): int
    {
        $from = $this->argument('from');
        $dir = is_dir($from) ? $from : base_path('database/backups/'.$from);
        if (config('database.connections.'.config('database.default').'.driver') === 'pgsql') {
            $rows = is_file($from) ? $from : $dir.'/legends.jsonl.gz';
            if (! is_file($rows)) {
                $this->error('لا نسخة هنا: '.$from);

                return self::FAILURE;
            }
            try {
                $counts = Copier::load($rows, config('database.default'));
            } catch (\Throwable $e) {
                $this->error('لم تُسترجع: '.$e->getMessage());

                return self::FAILURE;
            }
            $this->info('استُرجعت '.array_sum($counts).' صفاً.');

            return self::SUCCESS;
        }
        $files = is_file($from) ? [basename(config('database.connections.sqlite.database')) => $from]
            : (is_dir($dir) ? collect(File::files($dir))->mapWithKeys(fn ($f) => [$f->getFilename() => $f->getPathname()])->all() : []);
        if (! $files) {
            $this->error('لا نسخة هنا: '.$from);

            return self::FAILURE;
        }
        if (! $this->option('force') && ! $this->confirm('أوقفت اللعبة؟ ستُستبدل قواعد البيانات بالنسخة.')) {
            return self::FAILURE;
        }
        DB::disconnect();
        foreach (['sqlite', 'cache_db', 'queue_db'] as $connection) {
            $target = config("database.connections.$connection.database");
            $source = $files[basename($target)] ?? null;
            if (! $source) {
                continue;
            }
            // The check before anything changes: the copy must be a sound SQLite file.
            try {
                $ok = (new \PDO('sqlite:'.$source))->query('PRAGMA integrity_check')->fetchColumn();
            } catch (\PDOException $e) {
                $ok = $e->getMessage();
            }
            if ($ok !== 'ok') {
                $this->error(basename($source).' تالفة: '.$ok);

                return self::FAILURE;
            }
            if (is_file($target)) {
                File::copy($target, $target.'.before-restore');
            }
            foreach (['-wal', '-shm'] as $side) {
                File::delete($target.$side);
            }
            File::copy($source, $target);
            $this->line('استُرجعت '.basename($target));
        }
        $this->info('تم. شغّل اللعبة الآن.');

        return self::SUCCESS;
    }
}
