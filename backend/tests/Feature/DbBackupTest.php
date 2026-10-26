<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\File;
use Tests\TestCase;

class DbBackupTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        if (config('database.default') !== 'sqlite') {
            $this->markTestSkipped('The SQLite files only; on PostgreSQL (X43) CopierTest checks the backups.');
        }
    }

    protected function tearDown(): void
    {
        File::deleteDirectory(base_path('database/backups'));
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_it_copies_the_three_databases_and_keeps_only_the_newest(): void
    {
        File::deleteDirectory(base_path('database/backups'));

        foreach (['2026-10-18 04:00:00', '2026-10-19 04:00:00', '2026-10-20 04:00:00'] as $time) {
            Carbon::setTestNow($time);
            $this->artisan('db:backup', ['--keep' => 2])->assertSuccessful();
        }

        $dirs = File::directories(base_path('database/backups'));
        $this->assertCount(2, $dirs);
        $latest = collect($dirs)->sort()->last();
        $this->assertStringEndsWith('2026-10-20_040000', $latest);
        $this->assertCount(3, File::files($latest));

        // The copy is a real database with the committed schema in it.
        $copy = new \PDO('sqlite:'.$latest.'/'.basename(config('database.connections.sqlite.database')));
        $this->assertGreaterThan(0, (int) $copy->query('select count(*) from migrations')->fetchColumn());
    }
}
