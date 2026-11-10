<?php

namespace App\Store;

use App\Database\Sql;
use App\Models\Club;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [Sprint 50 M21] The store's chests: bronze, silver and the legend vault, bought with the coach's coins in a league.
 * Each holds one reward drawn from its table, the odds shown on the chest itself before it is opened: coins back, more
 * fitness or training for the squad, or the club's morale. Never club money (coins never turn into it) and never a
 * player. The roll and what it gave are kept as they fell (chest_openings, never changed); the coins move by the
 * wallet's own rules (a fair league spends none, the season's cap holds), and one key opens one chest.
 */
class Chests
{
    public const REWARDS = ['coins', 'fitness', 'training', 'morale'];

    /** The chests with their price and their odds (in percent of 100, from the weights). */
    public static function catalog(): array
    {
        return collect(config('game.chests'))->map(function ($c, $name) {
            $total = array_sum(array_column($c['table'], 'weight'));

            return ['chest' => $name, 'coins' => (int) $c['coins'],
                'odds' => array_map(fn ($r) => ['reward' => $r['reward'], 'amount' => (int) $r['amount'], 'pct_bp' => intdiv(10000 * (int) $r['weight'], $total)], $c['table'])];
        })->values()->all();
    }

    public static function open(Club $club, int $userId, string $chest, string $key): array
    {
        $c = config("game.chests.{$chest}");
        abort_unless($c, 404, __('الصندوق غير موجود.'));
        $done = DB::table('chest_openings')->where('idempotency_key', $key)->first();
        if ($done) {
            return self::view($done);
        }

        return DB::transaction(function () use ($club, $userId, $chest, $c, $key) {
            Wallet::pay($userId, (int) $club->league_id, 'chest', (int) $c['coins'], "chest:{$key}", "chest:{$chest}");
            $total = array_sum(array_column($c['table'], 'weight'));
            $roll = random_int(0, $total - 1);
            $pick = self::pick($c['table'], $roll);
            $amount = (int) $pick['amount'];
            match ($pick['reward']) {
                'coins' => Wallet::post($userId, 'chest', $amount, "chest:{$key}:coins", "chest:{$chest}", (int) $club->league_id),
                'fitness' => DB::table('players')->where('club_id', $club->id)->update(['fitness' => Sql::least("fitness + {$amount}", 100)]),
                'training' => DB::table('players')->where('club_id', $club->id)
                    ->update(['training_progress' => Sql::least("training_progress + {$amount}", (int) config('game.training.progress_scale') - 1)]),
                'morale' => DB::table('clubs')->where('id', $club->id)->update(['morale' => Sql::least("morale + {$amount}", 100)]),
            };
            $id = DB::table('chest_openings')->insertGetId(['user_id' => $userId, 'club_id' => $club->id, 'chest' => $chest, 'roll' => $roll,
                'reward' => $pick['reward'], 'amount' => $amount, 'idempotency_key' => $key, 'created_at' => GameClock::now()]);

            return self::view(DB::table('chest_openings')->find($id));
        });
    }

    /** The reward a roll lands on: the weights laid end to end, in the table's order. */
    public static function pick(array $table, int $roll): array
    {
        foreach ($table as $r) {
            $roll -= (int) $r['weight'];
            if ($roll < 0) {
                return $r;
            }
        }
        throw new HttpException(500, 'roll out of range');
    }

    private static function view(object $o): array
    {
        return ['chest' => $o->chest, 'reward' => $o->reward, 'amount' => (int) $o->amount];
    }
}
