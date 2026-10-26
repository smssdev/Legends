<?php

namespace App\Database;

use Generator;
use Illuminate\Database\PostgresConnection as BaseConnection;
use PDO;

/**
 * PostgreSQL (Supabase, X43) read as SQLite reads: a boolean column comes back 1 or 0, never true or false, so every
 * answer, every comparison and the engine's integer state are the same on both (the engine allows integers only).
 * And binary (an account's picture, bytea) goes in as binary and comes back as a string, as SQLite's blob does.
 */
class PostgresConnection extends BaseConnection
{
    public function select($query, $bindings = [], $useReadPdo = true)
    {
        return array_map(self::ints(...), parent::select($query, $bindings, $useReadPdo));
    }

    public function cursor($query, $bindings = [], $useReadPdo = true): Generator
    {
        foreach (parent::cursor($query, $bindings, $useReadPdo) as $row) {
            yield self::ints($row);
        }
    }

    public function bindValues($statement, $bindings)
    {
        foreach ($bindings as $key => $value) {
            $statement->bindValue(is_string($key) ? $key : $key + 1, $value, match (true) {
                is_int($value) => PDO::PARAM_INT,
                is_resource($value), is_string($value) && ! mb_check_encoding($value, 'UTF-8') => PDO::PARAM_LOB,
                default => PDO::PARAM_STR,
            });
        }
    }

    private static function ints(mixed $row): mixed
    {
        if (is_object($row)) {
            foreach (get_object_vars($row) as $k => $v) {
                if (is_bool($v)) {
                    $row->{$k} = (int) $v;
                } elseif (is_resource($v)) {
                    $row->{$k} = stream_get_contents($v);
                }
            }
        } elseif (is_array($row)) {
            foreach ($row as $k => $v) {
                if (is_bool($v)) {
                    $row[$k] = (int) $v;
                } elseif (is_resource($v)) {
                    $row[$k] = stream_get_contents($v);
                }
            }
        }

        return $row;
    }
}
