<?php

namespace App\Training;

use App\Data\PlayerValuation;
use App\Economy\Economy;
use App\League\ClubLedger;
use App\Messages\Inbox;
use App\Stadium\Stadium;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Training [PLAN 2.8, Sprint 27]: four slots, one player of each line. Every session (8 hours scaled by the
 * season's length) moves the player's bar by a random step and costs club money, the coach online or not. At
 * the full bar his rating and his six attributes (a keeper's four) go up by one, his value with them, and the
 * slot empties for the coach to fill again. Past his potential he still grows, slower, up to 99 [X16].
 */
class Training
{
    public const LINES = ['gk', 'def', 'mid', 'att'];

    /** A session's price: a slot busy all season costs cost_bp_per_season of the league's money scale. */
    public static function cost(int $leagueId): int
    {
        $cfg = config('game.training');

        return intdiv(Economy::scale($leagueId) * (int) $cfg['cost_bp_per_season'], 10000 * (int) $cfg['season_sessions']);
    }

    /** Seconds between two sessions in this league. */
    public static function interval(int $leagueId): int
    {
        $scale = (int) DB::table('leagues')->where('id', $leagueId)->value('timer_scale');

        return max(60, intdiv((int) config('game.training.tick_hours') * 3600 * max(1, $scale ?: 10000), 10000));
    }

    /** Put a player in his line's slot, in place of whoever was there. */
    public static function add(int $clubId, int $playerId): void
    {
        DB::transaction(function () use ($clubId, $playerId) {
            $p = self::player($playerId);
            if (! $p || (int) $p->club_id !== $clubId) {
                throw new HttpException(404, 'اللاعب ليس في فريقك.');
            }
            // Open training [X16]: past the potential too, only slower; 99 is the end.
            if ($p->overall + $p->training_bonus >= Gain::fromConfig()->ceiling()) {
                throw new HttpException(422, 'وصل هذا اللاعب إلى 99، أعلى تقييم في اللعبة.');
            }
            if (Camp::away($clubId, $playerId)) {
                throw new HttpException(409, 'اللاعب في المعسكر حتى يعود.');
            }
            if (DB::table('training_slots')->where('player_id', $playerId)->exists()) {
                throw new HttpException(409, 'اللاعب يتدرب الآن.');
            }
            $club = DB::table('clubs')->where('id', $clubId)->first();
            $now = GameClock::now();
            DB::table('training_slots')->where('club_id', $clubId)->where('line', $p->line)->delete();
            DB::table('training_slots')->insert(['club_id' => $clubId, 'line' => $p->line, 'player_id' => $playerId, 'sessions' => 0,
                'next_at' => $now->copy()->addSeconds(self::interval($club->league_id)), 'created_at' => $now, 'updated_at' => $now]);
        });
    }

    public static function remove(int $clubId, string $line): void
    {
        DB::table('training_slots')->where('club_id', $clubId)->where('line', $line)->delete();
    }

    /** Every minute: every session whose time has come, however many were missed. */
    public static function due(): int
    {
        $n = 0;
        foreach (DB::table('training_slots')->where('next_at', '<=', GameClock::now())->orderBy('next_at')->pluck('id') as $id) {
            $n += self::catchUp((int) $id);
        }

        return $n;
    }

    /** The sessions of one slot that are due. Returns how many ran. */
    public static function catchUp(int $slotId): int
    {
        $n = 0;
        while (($r = self::session($slotId)) !== null) {
            $n += $r;
        }

        return $n;
    }

    /**
     * One due session, or null when none is due (or the slot is gone). Claimed by moving next_at on, so two
     * workers never run the same session; returns 1 when it ran, 0 when it was skipped (no money).
     */
    public static function session(int $slotId): ?int
    {
        return DB::transaction(function () use ($slotId) {
            $slot = DB::table('training_slots')->where('id', $slotId)->first();
            if (! $slot || Carbon::parse($slot->next_at, 'UTC')->gt(GameClock::now())) {
                return null;
            }
            $club = DB::table('clubs')->where('id', $slot->club_id)->first();
            $p = self::player((int) $slot->player_id);
            // A player sold or at the ceiling (99), or a club left to the computer: the slot empties.
            if (! $p || (int) $p->club_id !== (int) $slot->club_id || ! $club->user_id || $p->overall + $p->training_bonus >= Gain::fromConfig()->ceiling()) {
                DB::table('training_slots')->where('id', $slotId)->delete();

                return null;
            }
            $next = Carbon::parse($slot->next_at, 'UTC')->addSeconds(self::interval($club->league_id));
            $claimed = DB::table('training_slots')->where('id', $slotId)->where('sessions', $slot->sessions)
                ->update(['sessions' => $slot->sessions + 1, 'next_at' => $next, 'updated_at' => GameClock::now()]);
            if ($claimed !== 1) {
                return null;
            }
            $session = $slot->sessions + 1;
            try {
                ClubLedger::post($club->id, 'training', -self::cost($club->league_id), "training:{$slotId}:{$session}", "player:{$p->id}", spend: true);
            } catch (HttpException) {
                return 0;   // no money: the session is missed, the bar stays
            }
            $key = "{$p->id}:{$slotId}:{$session}";
            $step = Stadium::trainingStep($club->id, Gain::fromConfig()->step($p->overall + $p->training_bonus, $key, (int) $p->potential), $key);
            if (! self::advance($p, $step)) {
                return 1;
            }
            DB::table('training_slots')->where('id', $slotId)->delete();
            Inbox::send($club->user_id, 'training_done', ['player' => $p->name, 'overall' => $p->overall + $p->training_bonus + 1], $club->league_id, $club->id);

            return 1;
        });
    }

    /**
     * Move a player's bar by $step. At the full bar: +1 on his rating (and value), the bar starts again. Returns
     * whether he went up. The caller holds the transaction and has checked the potential.
     */
    public static function advance(object $p, int $step): bool
    {
        $progress = $p->training_progress + $step;
        if ($progress < (int) config('game.training.progress_scale')) {
            DB::table('players')->where('id', $p->id)->update(['training_progress' => $progress]);

            return false;
        }
        $overall = $p->overall + $p->training_bonus + 1;
        $value = PlayerValuation::fromConfig()->value($overall, (int) $p->age, $p->line, (int) $p->potential);
        DB::table('players')->where('id', $p->id)->update(['training_bonus' => $p->training_bonus + 1, 'training_progress' => 0, 'value' => $value]);

        return true;
    }

    /** A squad row as the engine reads it, with the training on top: the rating and every attribute, up to 99. */
    public static function boosted(array $row, int $extra = 0): array
    {
        $bonus = (int) ($row['training_bonus'] ?? 0) + $extra;
        if ($bonus) {
            foreach (['overall', 'pac', 'sho', 'pas', 'dri', 'def', 'phy', 'gk_diving', 'gk_handling', 'gk_kicking', 'gk_positioning', 'gk_reflexes'] as $k) {
                if (isset($row[$k])) {
                    $row[$k] = min(99, (int) $row[$k] + $bonus);
                }
            }
        }

        return $row;
    }

    public static function player(int $id): ?object
    {
        return DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.id', $id)
            ->first(['players.id', 'players.club_id', 'players.overall', 'players.training_bonus', 'players.training_progress',
                'master_players.name', 'master_players.line', 'master_players.age', 'master_players.potential']);
    }
}
