<?php

namespace Tests\Feature;

use Tests\TestCase;

/**
 * The migrations only add [X33]: the owner's league runs on the live server, and every deploy runs
 * `migrate --force` over its data (deploy/docker/start.sh). So no migration's up() may drop, rename, truncate or
 * delete; a column that is no longer used stays, and a change of shape is a new column filled from the old one.
 * The undoing in down() is free (it never runs on the server).
 */
class MigrationSafetyTest extends TestCase
{
    private const DESTRUCTIVE = [
        'dropColumn', 'dropColumns', 'renameColumn', 'Schema::drop(', 'Schema::dropIfExists(', 'Schema::rename(',
        'dropTable', 'truncate(', '->delete(', 'DROP TABLE', 'DROP COLUMN', 'DELETE FROM', 'migrate:fresh', 'db:wipe',
    ];

    public function test_no_migration_removes_data_on_the_way_up(): void
    {
        $files = glob(database_path('migrations/*.php'));
        $this->assertNotEmpty($files);
        foreach ($files as $file) {
            $up = $this->up((string) file_get_contents($file));
            $this->assertNotSame('', $up, basename($file).': no up()');
            foreach (self::DESTRUCTIVE as $call) {
                $this->assertStringNotContainsStringIgnoringCase($call, $up, basename($file).": up() uses $call, which removes the live game's data");
            }
        }
    }

    /** The body of up(): from its signature to the next method (down) or the end of the class. */
    private function up(string $code): string
    {
        if (! preg_match('/function\s+up\s*\([^)]*\)[^{]*\{/', $code, $m, PREG_OFFSET_CAPTURE)) {
            return '';
        }
        $start = $m[0][1] + strlen($m[0][0]);
        $end = preg_match('/(public|protected|private)\s+function\s+\w+/', $code, $n, PREG_OFFSET_CAPTURE, $start) ? $n[0][1] : strlen($code);

        return substr($code, $start, $end - $start);
    }
}
