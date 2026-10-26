<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * Supabase's own API off the game's tables [X43]: Supabase opens every table of the public schema to anyone with the
 * project's public key (its Data API, the roles anon and authenticated). The game never uses that API; only the
 * server reaches the database, as the tables' owner. So every table gets row level security with no policy (the
 * owner passes, the API sees nothing) and those roles lose every right on the tables, now and for tables made later.
 * start.sh runs it after every migrate on Supabase. Elsewhere it does nothing.
 */
class DbCloseApi extends Command
{
    protected $signature = 'db:close-api';

    protected $description = 'Close Supabase\'s public API on the game\'s tables';

    public function handle(): int
    {
        if (DB::getDriverName() !== 'pgsql') {
            $this->info('Not PostgreSQL: nothing to close.');

            return self::SUCCESS;
        }
        $tables = DB::select('select tablename from pg_tables where schemaname = current_schema() and not rowsecurity');
        foreach ($tables as $t) {
            DB::statement("alter table \"{$t->tablename}\" enable row level security");
        }
        $roles = array_column(DB::select("select rolname from pg_roles where rolname in ('anon', 'authenticated')"), 'rolname');
        foreach ($roles as $role) {
            DB::statement("revoke all on all tables in schema public from \"{$role}\"");
            DB::statement("revoke all on all sequences in schema public from \"{$role}\"");
            DB::statement("alter default privileges in schema public revoke all on tables from \"{$role}\"");
            DB::statement("alter default privileges in schema public revoke all on sequences from \"{$role}\"");
        }
        $this->info('Supabase API closed: row level security on '.count($tables).' more tables'.($roles ? ', no rights for '.implode(' and ', $roles) : '').'.');

        return self::SUCCESS;
    }
}
