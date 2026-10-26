<?php

namespace App\Database;

use Illuminate\Contracts\Database\Query\Expression;
use Illuminate\Support\Facades\DB;

/**
 * SQL that means the same on SQLite (local, tests) and PostgreSQL (Supabase, X43): SQLite's min(a, b) and max(a, b)
 * are least() and greatest() on PostgreSQL, so both are written as a CASE, which both read alike.
 */
class Sql
{
    /** The smaller of a column expression and a whole number. */
    public static function least(string $expr, int $n): Expression
    {
        return DB::raw("case when {$expr} < {$n} then {$expr} else {$n} end");
    }

    /** The larger of a column expression and a whole number. */
    public static function greatest(string $expr, int $n): Expression
    {
        return DB::raw("case when {$expr} > {$n} then {$expr} else {$n} end");
    }
}
