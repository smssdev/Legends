<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Tests\TestCase;

/**
 * A backup and its restore [PLAN 2.19, Sprint 37]: db:backup copies a running database with VACUUM INTO, and
 * db:restore puts it back after the data changed, keeping the replaced file beside. On files of its own.
 */
class BackupRestoreTest extends TestCase
{
    private string $dir;

    protected function setUp(): void
    {
        parent::setUp();
        if (config('database.default') !== 'sqlite') {
            $this->markTestSkipped('The SQLite files only; on PostgreSQL (X43) CopierTest checks the backups.');
        }
        $this->dir = sys_get_temp_dir().'/legends-restore-'.getmypid();
        File::ensureDirectoryExists($this->dir);
        $db = $this->dir.'/game.sqlite';
        touch($db);
        config(['database.connections.restore_test' => ['driver' => 'sqlite', 'database' => $db, 'foreign_key_constraints' => true],
            'database.connections.sqlite.database' => $db,
            'database.connections.cache_db.database' => $this->dir.'/none-cache.sqlite',
            'database.connections.queue_db.database' => $this->dir.'/none-queue.sqlite']);
        DB::connection('restore_test')->statement('create table clubs (id integer primary key, name text)');
        DB::connection('restore_test')->table('clubs')->insert(['id' => 1, 'name' => 'Liverpool']);
    }

    protected function tearDown(): void
    {
        DB::purge('restore_test');
        if (isset($this->dir)) {
            File::deleteDirectory($this->dir);
        }
        parent::tearDown();
    }

    public function test_a_backup_comes_back_after_the_data_changed(): void
    {
        File::ensureDirectoryExists(base_path('database/backups'));
        $before = collect(File::directories(base_path('database/backups')))->all();
        $this->artisan('db:backup --keep=100')->assertSuccessful();
        $made = collect(File::directories(base_path('database/backups')))->diff($before)->first();
        $this->assertFileExists($made.'/game.sqlite');

        DB::connection('restore_test')->table('clubs')->update(['name' => 'Everton']);
        DB::purge('restore_test');
        $this->artisan('db:restore', ['from' => basename($made), '--force' => true])->assertSuccessful();
        $this->assertSame('Liverpool', DB::connection('restore_test')->table('clubs')->value('name'));
        $this->assertFileExists($this->dir.'/game.sqlite.before-restore');
        File::deleteDirectory($made);

        // A broken file is refused before anything changes.
        file_put_contents($this->dir.'/broken.sqlite', 'not a database');
        $this->artisan('db:restore', ['from' => $this->dir.'/broken.sqlite', '--force' => true])->assertFailed();
        $this->assertSame('Liverpool', DB::connection('restore_test')->table('clubs')->value('name'));
    }
}
