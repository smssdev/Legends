<?php

namespace Tests\Unit;

use PHPUnit\Framework\TestCase;
use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;

/**
 * Game logic reads time from GameClock only, so clock:travel and tests can move it [CLAUDE.md].
 * This fails on any other way of reading the wall clock in app/.
 */
class NoWallClockTest extends TestCase
{
    private const ALLOWED = ['Support/GameClock.php'];

    private const FORBIDDEN = [
        '/(?<![\w>:$])now\(\)/' => 'now()',
        '/Carbon(Immutable)?::now\(/' => 'Carbon::now()',
        '/(?<![\w>:$])today\(\)/' => 'today()',
        '/(?<![\w>:$])time\(\)/' => 'time()',
        '/(?<![\w>:$])microtime\(/' => 'microtime()',
        '/(?<![\w>:$])date\(/' => 'date()',
        '/new\s+\\\\?DateTime(Immutable)?\(\s*\)/' => 'new DateTime()',
        '/(?<![\w>:$])hrtime\(/' => 'hrtime()',
    ];

    public function test_game_code_never_reads_the_wall_clock_directly(): void
    {
        $root = dirname(__DIR__, 2).'/app/';
        $found = [];
        foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root)) as $file) {
            if ($file->getExtension() !== 'php') {
                continue;
            }
            $rel = substr($file->getPathname(), strlen($root));
            if (in_array($rel, self::ALLOWED, true)) {
                continue;
            }
            foreach (file($file->getPathname()) as $i => $line) {
                $code = preg_replace('#//.*$|^\s*\*.*$#', '', $line);
                foreach (self::FORBIDDEN as $re => $name) {
                    if (preg_match($re, $code)) {
                        $found[] = "$rel:".($i + 1)." uses $name";
                    }
                }
            }
        }
        $this->assertSame([], $found, "Use App\\Support\\GameClock instead:\n".implode("\n", $found));
    }
}
