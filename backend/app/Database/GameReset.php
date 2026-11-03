<?php

namespace App\Database;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * [X95] A fresh start of the whole game, the owner's (2026-11-03): every league, club, match, coin, message and
 * account goes, except the admins' accounts (role admin: they sign in again with their own Gmail, and the developers'
 * official addresses get the role back on sign-in, OfficialAccounts) and what the game is made of: the master data
 * (the clubs and players, and the data editor's log), the admin's settings and the house ads. Run by hand only, on
 * the server (legends-reset, after a backup): never from a deploy, a migration or the scheduler.
 */
class GameReset
{
    /** Kept whole: the schema's record, the game's data and the admin's own settings. */
    public const KEEP = ['migrations', 'users', 'master_clubs', 'master_players', 'data_edits', 'game_settings', 'house_ads'];

    /** The tables emptied, with their rows now (what a reset would take). */
    public static function plan(): array
    {
        $plan = [];
        foreach (self::tables() as $table) {
            if (! in_array($table, self::KEEP, true)) {
                $plan[$table] = DB::table($table)->count();
            }
        }
        $plan['users (not admins)'] = self::others()->count();

        return $plan;
    }

    /** The admins kept, by id: their name, username and email. */
    public static function admins(): array
    {
        return DB::table('users')->where('role', 'admin')->orderBy('id')->get(['id', 'name', 'username', 'email'])->map(fn ($u) => (array) $u)->all();
    }

    /** Empty the game, keeping the admins and the game's data. Returns the users removed. */
    public static function run(): int
    {
        $tables = array_values(array_diff(self::tables(), self::KEEP));
        $driver = DB::connection()->getDriverName();
        if ($driver === 'pgsql') {
            return DB::transaction(function () use ($tables) {
                // One statement, no CASCADE: a kept table that pointed at an emptied one would stop it all.
                if ($tables) {
                    DB::statement('TRUNCATE TABLE '.implode(', ', array_map(fn ($t) => '"'.$t.'"', $tables)).' RESTART IDENTITY');
                }

                return self::others()->delete();
            });
        }
        DB::statement('PRAGMA foreign_keys = OFF');
        try {
            return DB::transaction(function () use ($tables) {
                foreach ($tables as $t) {
                    DB::table($t)->delete();
                }
                if (Schema::hasTable('sqlite_sequence')) {
                    DB::table('sqlite_sequence')->whereIn('name', $tables)->delete();
                }

                return self::others()->delete();
            });
        } finally {
            DB::statement('PRAGMA foreign_keys = ON');
        }
    }

    private static function others()
    {
        return DB::table('users')->where(fn ($q) => $q->where('role', '!=', 'admin')->orWhereNull('role'));
    }

    /** The game's tables on its connection (PostgreSQL's public schema). */
    private static function tables(): array
    {
        return collect(Schema::getTables())
            ->filter(fn ($t) => ($t['schema'] ?? 'public') === 'public' || DB::connection()->getDriverName() !== 'pgsql')
            ->pluck('name')->reject(fn ($n) => $n === 'sqlite_sequence')->unique()->values()->all();
    }
}
