<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class SqliteSetupTest extends TestCase
{
    use RefreshDatabase;

    private const CONNECTIONS = ['sqlite', 'cache_db', 'queue_db'];

    public function test_every_connection_uses_wal_foreign_keys_and_a_busy_timeout(): void
    {
        foreach (self::CONNECTIONS as $name) {
            $db = DB::connection($name);

            $this->assertSame('wal', $db->selectOne('pragma journal_mode')->journal_mode, $name);
            $this->assertSame(1, (int) $db->selectOne('pragma foreign_keys')->foreign_keys, $name);
            $this->assertSame(5000, (int) $db->selectOne('pragma busy_timeout')->timeout, $name);
        }
    }

    public function test_data_cache_and_queue_live_in_separate_files(): void
    {
        $files = array_map(fn ($name) => config("database.connections.$name.database"), self::CONNECTIONS);

        $this->assertCount(3, array_unique($files));
        foreach ($files as $file) {
            $this->assertFileExists($file);
        }
    }

    public function test_tables_are_created_on_their_own_connection(): void
    {
        $tables = fn ($name) => array_column(
            DB::connection($name)->select("select name from sqlite_master where type = 'table'"),
            'name'
        );

        $this->assertContains('users', $tables('sqlite'));
        $this->assertNotContains('cache', $tables('sqlite'));
        $this->assertNotContains('jobs', $tables('sqlite'));
        $this->assertContains('cache', $tables('cache_db'));
        $this->assertContains('jobs', $tables('queue_db'));
        $this->assertContains('failed_jobs', $tables('queue_db'));
    }
}
