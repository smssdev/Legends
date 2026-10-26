<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * [X43] On PostgreSQL (Supabase) a string column has no length limit, as on SQLite, which never checked one: the
 * league moves from SQLite with its values as they are (an 'alliance' fixture, a long name), and the game writes
 * them as it always did. Only the type of the column changes (varchar to text); nothing is dropped. SQLite: nothing.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            return;
        }
        $columns = DB::select("select table_name, column_name from information_schema.columns where table_schema = current_schema() and data_type = 'character varying'");
        foreach ($columns as $c) {
            DB::statement("alter table \"{$c->table_name}\" alter column \"{$c->column_name}\" type text");
        }
    }
};
