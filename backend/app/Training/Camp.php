<?php

namespace App\Training;

use App\League\ClubLedger;
use App\Messages\Inbox;
use App\Stadium\Stadium;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * The training camp [docs/features/camp.md, Sprint 28]: up to five players away for one to three days, missing the
 * club's matches, with a session each at training's pace (and the camp level's step), paid in full when they go.
 * They come back on time, coach online or not, with a message of what each gained.
 */
class Camp
{
    public const LEVELS = ['basic', 'good', 'elite'];

    /** The camp's whole price: players × sessions × a training session's price × the level. */
    public static function price(int $leagueId, string $level, int $players, int $days): int
    {
        return intdiv(Training::cost($leagueId) * $players * self::sessions($days) * (int) config("game.camp.levels.{$level}.cost_bp"), 10000);
    }

    /** Sessions in so many days (three a day at the reference length). */
    public static function sessions(int $days): int
    {
        return intdiv($days * 24, (int) config('game.training.tick_hours'));
    }

    /** The club's camp under way, if any. */
    public static function active(int $clubId): ?object
    {
        return DB::table('training_camps')->where('club_id', $clubId)->where('status', 'active')->first();
    }

    /** The club's players at the camp now. */
    public static function awayIds(int $clubId): array
    {
        $camp = self::active($clubId);

        return $camp ? json_decode($camp->player_ids, true) : [];
    }

    public static function away(int $clubId, int $playerId): bool
    {
        return in_array($playerId, self::awayIds($clubId), true);
    }

    /** Send players to the camp. Returns the camp's id. */
    public static function send(int $clubId, array $playerIds, string $level, int $days, string $key): int
    {
        return DB::transaction(function () use ($clubId, $playerIds, $level, $days, $key) {
            $done = DB::table('training_camps')->where('idempotency_key', $key)->value('id');
            if ($done) {
                return (int) $done;
            }
            $cfg = config('game.camp');
            $playerIds = array_values(array_unique(array_map('intval', $playerIds)));
            if (! $playerIds || count($playerIds) > $cfg['max_players']) {
                throw new HttpException(422, "المعسكر من لاعب إلى {$cfg['max_players']} لاعبين.");
            }
            if (self::active($clubId)) {
                throw new HttpException(409, 'لديك معسكر جارٍ، انتظر عودة لاعبيه.');
            }
            $club = DB::table('clubs')->where('id', $clubId)->first();
            if (DB::table('players')->whereIn('id', $playerIds)->where('club_id', $clubId)->count() !== count($playerIds)) {
                throw new HttpException(404, 'اللاعب ليس في فريقك.');
            }
            $squad = DB::table('players')->where('club_id', $clubId)->count();
            if ($squad - count($playerIds) < $cfg['min_left']) {
                throw new HttpException(422, "يجب أن يبقى {$cfg['min_left']} لاعباً على الأقل خارج المعسكر.");
            }
            $now = GameClock::now();
            $interval = Training::interval($club->league_id);
            $sessions = self::sessions($days);
            $cost = self::price($club->league_id, $level, count($playerIds), $days);
            $id = DB::table('training_camps')->insertGetId([
                'club_id' => $clubId, 'level' => $level, 'player_ids' => json_encode($playerIds), 'gains' => '{}', 'sessions' => $sessions,
                'cost' => $cost, 'next_at' => $now->copy()->addSeconds($interval), 'ends_at' => $now->copy()->addSeconds($interval * $sessions),
                'status' => 'active', 'idempotency_key' => $key, 'created_at' => $now, 'updated_at' => $now,
            ]);
            ClubLedger::post($clubId, 'camp', -$cost, "camp:{$id}", "camp:{$id}", spend: true);
            DB::table('training_slots')->whereIn('player_id', $playerIds)->delete();

            return $id;
        });
    }

    /** Every minute: the camps' due sessions, and the returns. */
    public static function due(): int
    {
        $n = 0;
        foreach (DB::table('training_camps')->where('status', 'active')->where('next_at', '<=', GameClock::now())->pluck('id') as $id) {
            while (self::session((int) $id)) {
                $n++;
            }
        }

        return $n;
    }

    /** One due session for every player at the camp; the last one brings them back. False when none is due. */
    public static function session(int $campId): bool
    {
        return DB::transaction(function () use ($campId) {
            $camp = DB::table('training_camps')->where('id', $campId)->first();
            if (! $camp || $camp->status !== 'active' || Carbon::parse($camp->next_at, 'UTC')->gt(GameClock::now())) {
                return false;
            }
            $club = DB::table('clubs')->where('id', $camp->club_id)->first();
            $done = $camp->sessions_done + 1;
            $last = $done >= $camp->sessions;
            $claimed = DB::table('training_camps')->where('id', $campId)->where('sessions_done', $camp->sessions_done)->update([
                'sessions_done' => $done, 'status' => $last ? 'done' : 'active', 'updated_at' => GameClock::now(),
                'next_at' => Carbon::parse($camp->next_at, 'UTC')->addSeconds(Training::interval($club->league_id)),
            ]);
            if ($claimed !== 1) {
                return false;
            }
            $gain = Gain::fromConfig();
            $level = (int) config("game.camp.levels.{$camp->level}.gain_bp");
            $gains = json_decode($camp->gains, true) ?: [];
            foreach (json_decode($camp->player_ids, true) as $id) {
                $p = Training::player($id);
                if (! $p || (int) $p->club_id !== (int) $camp->club_id || $p->overall + $p->training_bonus >= $gain->ceiling()) {
                    continue;
                }
                $key = "camp:{$campId}:{$id}:{$done}";
                $step = Stadium::trainingStep($club->id, intdiv($gain->step($p->overall + $p->training_bonus, $key, (int) $p->potential) * $level, 10000), $key);
                if (Training::advance($p, $step)) {
                    $gains[$id] = ($gains[$id] ?? 0) + 1;
                }
            }
            DB::table('training_camps')->where('id', $campId)->update(['gains' => json_encode((object) $gains)]);
            if ($last && $club->user_id) {
                $names = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
                    ->whereIn('players.id', json_decode($camp->player_ids, true))->pluck('master_players.name', 'players.id');
                Inbox::send($club->user_id, 'camp_back', ['players' => $names->map(fn ($n, $id) => ['name' => $n, 'gain' => $gains[$id] ?? 0])->values()->all()],
                    $club->league_id, $club->id);
            }

            return true;
        });
    }
}
