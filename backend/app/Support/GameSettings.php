<?php

namespace App\Support;

use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 27 X65] The settings the admin changes from the panel without a deploy, as JSON by key; a key never set reads
 * its default from config/game.php (game.settings).
 */
class GameSettings
{
    public static function get(string $key): mixed
    {
        $stored = Cache::remember("game_settings:{$key}", 60, fn () => DB::table('game_settings')->where('key', $key)->value('value'));

        return $stored === null ? (config('game.settings')[$key] ?? null) : json_decode($stored, true);
    }

    public static function set(string $key, mixed $value): void
    {
        DB::table('game_settings')->updateOrInsert(['key' => $key], ['value' => json_encode($value), 'updated_at' => GameClock::now()]);
        Cache::forget("game_settings:{$key}");
    }
}
