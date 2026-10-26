<?php

namespace App\Database;

use Illuminate\Database\Connection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use RuntimeException;

/**
 * The game's data from one database to another [X43]: the league on Render's SQLite into Supabase (PostgreSQL)
 * once, and Supabase into a backup file and back. The target is migrated already and holds no game yet: every
 * table is copied in its foreign keys' order (a club before its players), in one transaction, so it is all or
 * nothing, then each table is counted on both sides. The source is only read.
 *
 * A backup file is JSON lines, gzipped: {"table": ..., "row": {...}} per row, in the same order; a binary value
 * (an account's picture) as {"b64": ...}.
 */
class Copier
{
    /** Kept by each side itself: the migrations it ran, and the cache and queue (rebuilt or short-lived). The sign-ins
     * (sessions) move with the game, so nobody is signed out by the move. */
    private const SKIP = ['migrations', 'cache', 'cache_locks', 'jobs', 'job_batches', 'failed_jobs'];

    /** The tables that say a game is there: a target with any of these rows is never written over. */
    private const GAME = ['users', 'leagues', 'clubs'];

    private const CHUNK = 500;

    /** The game's tables of a connection, parents first. */
    public static function tables(string $connection): array
    {
        $schema = Schema::connection($connection);
        $names = array_values(array_diff(array_map(fn ($t) => $t['name'], $schema->getTables()), self::SKIP));
        $parents = [];
        foreach ($names as $t) {
            $parents[$t] = array_values(array_intersect(array_diff(array_map(fn ($f) => $f['foreign_table'], $schema->getForeignKeys($t)), [$t]), $names));
        }
        $order = [];
        $visit = function (string $t, array $path) use (&$visit, &$order, $parents) {
            if (in_array($t, $order, true) || in_array($t, $path, true)) {
                return;
            }
            foreach ($parents[$t] as $p) {
                $visit($p, [...$path, $t]);
            }
            $order[] = $t;
        };
        sort($names);
        foreach ($names as $t) {
            $visit($t, []);
        }

        return $order;
    }

    /** Whether a connection already holds a game. */
    public static function hasGame(string $connection): bool
    {
        $schema = Schema::connection($connection);
        foreach (self::GAME as $t) {
            if ($schema->hasTable($t) && DB::connection($connection)->table($t)->exists()) {
                return true;
            }
        }

        return false;
    }

    /**
     * Copy every game table from one connection into another that has none of it. Returns the rows per table.
     *
     * @return array<string, int>
     */
    public static function copy(string $from, string $to): array
    {
        if (self::hasGame($to)) {
            throw new RuntimeException("The target ({$to}) already holds a game: nothing is written over it.");
        }
        $source = DB::connection($from);
        $have = self::tables($from);

        return self::write($to, function (callable $put) use ($source, $have, $to) {
            foreach (self::tables($to) as $table) {
                if (! in_array($table, $have, true)) {
                    continue;
                }
                $columns = array_values(array_intersect(Schema::connection($to)->getColumnListing($table), Schema::connection($source->getName())->getColumnListing($table)));
                $key = in_array('id', $columns, true) ? 'id' : $columns[0];
                foreach ($source->table($table)->select($columns)->orderBy($key)->lazy(self::CHUNK) as $row) {
                    $put($table, (array) $row);
                }
            }
        });
    }

    /** Write a connection's game into a backup file. Returns the rows per table. */
    public static function dump(string $from, string $file): array
    {
        $out = gzopen($file, 'wb6');
        $counts = [];
        $source = DB::connection($from);
        foreach (self::tables($from) as $table) {
            $counts[$table] = 0;
            $key = Schema::connection($from)->hasColumn($table, 'id') ? 'id' : Schema::connection($from)->getColumnListing($table)[0];
            foreach ($source->table($table)->orderBy($key)->lazy(self::CHUNK) as $row) {
                $row = array_map(fn ($v) => is_string($v) && ! mb_check_encoding($v, 'UTF-8') ? ['b64' => base64_encode($v)] : $v, (array) $row);
                gzwrite($out, json_encode(['table' => $table, 'row' => $row], JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR)."\n");
                $counts[$table]++;
            }
        }
        gzclose($out);

        return $counts;
    }

    /** Bring a backup file into a connection that holds no game. Returns the rows per table. */
    public static function load(string $file, string $to): array
    {
        if (self::hasGame($to)) {
            throw new RuntimeException("The target ({$to}) already holds a game: nothing is written over it.");
        }

        return self::write($to, function (callable $put) use ($file) {
            $in = gzopen($file, 'rb');
            while (($line = gzgets($in)) !== false) {
                if (trim($line) !== '') {
                    $r = json_decode($line, true, 512, JSON_THROW_ON_ERROR);
                    $put($r['table'], array_map(fn ($v) => is_array($v) && isset($v['b64']) ? base64_decode($v['b64']) : $v, $r['row']));
                }
            }
            gzclose($in);
        });
    }

    /**
     * The rows the reader gives, into $to in one transaction: booleans as booleans, in chunks, the id sequences
     * moved past the copied ids (PostgreSQL), and every table counted after.
     */
    private static function write(string $to, callable $read): array
    {
        $db = DB::connection($to);
        $schema = Schema::connection($to);
        $tables = self::tables($to);
        $columns = [];
        foreach ($tables as $t) {
            foreach ($schema->getColumns($t) as $c) {
                $columns[$t][$c['name']] = in_array(strtolower($c['type_name']), ['bool', 'boolean'], true);
            }
        }
        $counts = array_fill_keys($tables, 0);
        $db->transaction(function () use ($db, $read, $columns, &$counts) {
            $batch = [];
            $current = null;
            $flush = function () use ($db, &$batch, &$current) {
                if ($batch) {
                    $db->table($current)->insert($batch);
                    $batch = [];
                }
            };
            $read(function (string $table, array $row) use (&$batch, &$current, $flush, $columns, &$counts) {
                if (! isset($columns[$table])) {
                    return;
                }
                if ($table !== $current || count($batch) >= self::CHUNK) {
                    $flush();
                    $current = $table;
                }
                $row = array_intersect_key($row, $columns[$table]);
                foreach ($row as $k => $v) {
                    if ($columns[$table][$k] && $v !== null) {
                        $row[$k] = (bool) $v;
                    }
                }
                $batch[] = $row;
                $counts[$table]++;
            });
            $flush();
            if ($db->getDriverName() === 'pgsql') {
                self::sequences($db, array_keys(array_filter($columns, fn ($c) => isset($c['id']))));
            }
        });
        foreach ($counts as $t => $n) {
            $there = $db->table($t)->count();
            if ($there !== $n) {
                throw new RuntimeException("{$t}: {$n} rows copied, {$there} there.");
            }
        }

        return $counts;
    }

    /** Each table's id sequence past its highest id, so the next row made gets a new one. */
    private static function sequences(Connection $db, array $tables): void
    {
        foreach ($tables as $t) {
            $seq = $db->selectOne('select pg_get_serial_sequence(?, ?) as s', [$t, 'id'])?->s ?? null;
            if ($seq) {
                $db->statement("select setval(?, coalesce((select max(id) from \"{$t}\"), 0) + 1, false)", [$seq]);
            }
        }
    }
}
