<?php

namespace App\Economy;

use App\League\ClubLedger;
use App\Market\Market;
use App\Market\Transfers;
use App\Models\League;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [X61 E1] The players' contracts within a season (every season starts again from the data, so a contract runs to
 * the season's end): each player's wage a round (his share of the wages the club already pays, Money::wages), a wage
 * cap (the squad's value may grow to wage_cap_bp of the larger of the league's scale and the club's own squad in the
 * data), and ending a contract early: the player leaves for the market and the club pays release_bp of the wages left
 * in the season.
 */
class Contracts
{
    public static function wage(int $value, int $rounds): int
    {
        return Money::fromConfig()->wages($value, $rounds);
    }

    /** The most the squad's value may reach (its wages follow it). */
    public static function cap(object $club): int
    {
        $data = (int) DB::table('master_players')->where('master_club_id', $club->master_club_id)
            ->where('data_version', DB::table('master_players')->max('data_version'))->sum('value');

        return intdiv(max(Economy::scale($club->league_id), $data) * (int) config('game.contracts.wage_cap_bp'), 10000);
    }

    /** Refused when a new player would take the squad over its cap. */
    public static function assertRoom(int $clubId, int $value): void
    {
        $club = DB::table('clubs')->where('id', $clubId)->first();
        if (Economy::squadValue($clubId) + $value > self::cap($club)) {
            throw new HttpException(409, __('سقف الرواتب: هذا اللاعب يتجاوز ما يتحمله ناديك من رواتب هذا الموسم. بِع أو أنهِ عقد لاعب أولاً.'));
        }
    }

    /** The compensation to end this player's contract now. */
    public static function release(object $club, object $season, int $value): int
    {
        $left = max(0, (int) $season->rounds - (int) $season->rounds_played);

        return intdiv(self::wage($value, (int) $season->rounds) * $left * (int) config('game.contracts.release_bp'), 10000);
    }

    /** End a contract: the player goes to the market (not this season's pool), the club pays the compensation. */
    public static function end(object $club, int $playerId): int
    {
        return DB::transaction(function () use ($club, $playerId) {
            $p = DB::table('players')->where('id', $playerId)->where('club_id', $club->id)->first();
            abort_unless($p, 404, __('اللاعب ليس في فريقك.'));
            if (DB::table('player_loans')->where('player_id', $playerId)->where('status', 'active')->exists()) {
                throw new HttpException(409, 'لا يُنهى عقد لاعب معار.');
            }
            Market::assertKeeps($club->id, $p, (int) config('game.economy.min_squad'), __('لا يمكن أن ينزل فريقك عن %d لاعباً.'));
            $season = League::find($club->league_id)->season;
            $pay = self::release($club, $season, (int) $p->value);
            if (DB::table('players')->where('id', $playerId)->where('club_id', $club->id)->update(['club_id' => null, 'in_pool' => false, 'updated_at' => GameClock::now()]) !== 1) {
                throw new HttpException(409, 'تغير حال اللاعب، حاول مجدداً.');
            }
            DB::table('training_slots')->where('player_id', $playerId)->delete();
            Transfers::left($playerId, $club->id);
            if ($pay > 0) {
                ClubLedger::post($club->id, 'contract_release', -$pay, "release:{$club->id}:{$playerId}:{$season->id}", "player:{$playerId}");
            }

            return $pay;
        });
    }

    /** The squad's contracts: each player's wage and what ending it costs, the wages, the cap and the room left. */
    public static function view(object $club, object $season): array
    {
        $rounds = (int) $season->rounds;
        $players = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.club_id', $club->id)
            ->orderByDesc('players.value')->get(['players.id', 'players.value', 'master_players.name', 'master_players.position', 'master_players.age']);
        $value = (int) $players->sum('value');
        $cap = self::cap($club);

        return [
            'players' => $players->map(fn ($p) => ['id' => (int) $p->id, 'name' => $p->name, 'position' => $p->position, 'age' => (int) $p->age, 'value' => (int) $p->value,
                'wage' => self::wage((int) $p->value, $rounds), 'release' => self::release($club, $season, (int) $p->value)])->all(),
            'wages_per_round' => self::wage($value, $rounds),
            'cap_per_round' => self::wage($cap, $rounds),
            'room' => max(0, $cap - $value),
            'rounds_left' => max(0, $rounds - (int) $season->rounds_played),
        ];
    }
}
