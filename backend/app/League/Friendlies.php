<?php

namespace App\League;

use App\Database\Sql;
use App\Models\Club;
use App\Simulator\Runner;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Friendlies [Sprint 20 B4; Sprint 24 B2, the owner's decision 2026-10-29: game.friendlies.coins (5) each, no daily
 * limit]: a match now against any club of the league, played whole by the engine from both sheets as they stand,
 * with **no effect** on the table, the money, the fitness or the injuries. It adds game.friendlies.training_progress
 * to the bar of each of the coach's players who played (never past the bar: the +1 itself comes from a training
 * session), and counts as a match played together for the chemistry. The coins are taken with the match, in one
 * write, once by the request's key. In a fair league no coins are spent, so there it is free and per_day a day.
 * Not in the last game.friendlies.block_minutes before the club's next match, nor while it is live.
 */
class Friendlies
{
    /** What the screen shows: the friendlies left today, why none can be played now, and the opponents. */
    public static function view(Club $club): array
    {
        $cfg = config('game.friendlies');
        $opponents = DB::table('clubs')->leftJoin('users', 'users.id', '=', 'clubs.user_id')->where('clubs.league_id', $club->league_id)->where('clubs.id', '!=', $club->id)
            ->get(['clubs.id', 'clubs.name', 'clubs.code', 'clubs.master_club_id', 'clubs.strength_snapshot', 'users.name as coach']);
        // Recommended: the closest in strength.
        $closest = $opponents->sortBy(fn ($o) => abs($o->strength_snapshot - $club->strength_snapshot))->first()?->id;

        $fair = self::fair($club);

        return ['coins' => $fair ? 0 : (int) $cfg['coins'], 'balance' => $club->user_id ? Wallet::balance((int) $club->user_id) : 0,
            'max' => $fair ? (int) $cfg['per_day'] : null, 'left' => $fair ? self::left($club) : null, 'blocked' => self::blocked($club),
            'training_progress_pct' => intdiv((int) $cfg['training_progress'] * 100, (int) config('game.training.progress_scale')),
            'opponents' => $opponents->sortByDesc('strength_snapshot')->values()->map(fn ($o) => ['id' => (int) $o->id, 'name' => $o->name, 'code' => $o->code,
                'crest_url' => url("/api/v1/data/clubs/{$o->master_club_id}/crest.svg"), 'strength_cp' => (int) $o->strength_snapshot, 'coach' => $o->coach, 'recommended' => $o->id === $closest])->all(),
            'recent' => DB::table('friendlies')->where('club_id', $club->id)->orderByDesc('id')->limit(5)->get()->map(fn ($f) => self::row($f))->all()];
    }

    /** A fair league spends no coins [UP9]: its friendlies are free, per_day a day. */
    public static function fair(Club $club): bool
    {
        return (bool) DB::table('leagues')->where('id', $club->league_id)->value('fair_league');
    }

    public static function left(Club $club): int
    {
        return max(0, (int) config('game.friendlies.per_day') - DB::table('friendlies')->where('club_id', $club->id)->where('day', self::cairoDay())->count());
    }

    /** Why a friendly cannot be played now (null: it can): the club's match is live or due within block_minutes. */
    public static function blocked(Club $club): ?array
    {
        $f = ClubAgenda::nextFixture($club);
        if (! $f) {
            return null;
        }
        if ($f->status === 'live') {
            return ['reason' => 'live'];
        }
        $at = Carbon::parse($f->scheduled_at, 'UTC');

        return GameClock::now()->gte($at->copy()->subMinutes((int) config('game.friendlies.block_minutes'))) ? ['reason' => 'before_match', 'until' => $at->toIso8601ZuluString()] : null;
    }

    /** @return array{0: array, 1: bool} the friendly, and whether it is new (false: this key already played it). */
    public static function play(Club $club, int $opponentId, int $userId, string $key): array
    {
        $key = "{$club->id}:{$key}";
        if ($done = DB::table('friendlies')->where('idempotency_key', $key)->first()) {
            return [self::row($done), false];
        }
        $opponent = Club::where('league_id', $club->league_id)->where('id', '!=', $club->id)->find($opponentId);
        if (! $opponent) {
            throw new HttpException(404, 'هذا النادي ليس في دوريك.');
        }
        if (self::blocked($club)) {
            throw new HttpException(409, 'لا وديات قبل مباراتك بساعة ولا أثناءها.');
        }
        $fair = self::fair($club);
        $coins = (int) config('game.friendlies.coins');
        // Before playing it: a friendly the coach cannot pay for is not played.
        if (! $fair && Wallet::balance($userId) < $coins) {
            throw new HttpException(409, sprintf(__('الودية بـ %d كوينز، ورصيدك لا يكفي.'), $coins));
        }
        $seed = random_int(1, 2_000_000_000);
        $state = LeagueMatch::friendly($club, $opponent, $seed);
        $goals = [];
        while (! $state['finished']) {
            $state = Runner::tick($state);
            foreach ($state['out']['events'] ?? [] as $e) {
                if ($e['type'] === 'goal') {
                    $goals[] = ['minute' => is_array($state['out']['minute'] ?? null) ? array_sum($state['out']['minute']) : (int) ($state['out']['minute'] ?? $state['out']['tick']),
                        'side' => $e['team'], 'scorer' => $e['scorer'] ?? null];
                }
            }
        }
        $mine = $state['teams']['home']['players'];
        $played = array_values(array_filter($mine, fn ($p) => $p['on'] || $p['out'] !== ''));
        $names = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->whereIn('players.id', array_merge(array_column($state['teams']['home']['players'], 'id'), array_column($state['teams']['away']['players'], 'id')))->pluck('master_players.name', 'players.id');
        usort($played, fn ($a, $b) => $b['st']['r'] <=> $a['st']['r']);
        $report = ['goals' => array_map(fn ($g) => $g + ['name' => $g['scorer'] ? ($names[$g['scorer']] ?? null) : null], $goals),
            'best' => array_map(fn ($p) => ['id' => (int) $p['id'], 'name' => $names[$p['id']] ?? null, 'rating' => (int) $p['st']['r']], array_slice($played, 0, 3)),
            'played' => count($played), 'coins' => $fair ? 0 : $coins];

        try {
            return DB::transaction(function () use ($club, $opponent, $userId, $seed, $state, $played, $report, $fair, $coins, $key) {
                if ($fair) {
                    // The limit, inside the write: two taps at once count as two.
                    if (self::left($club) < 1) {
                        throw new HttpException(429, sprintf(__('لعبت وديات اليوم كلها (%d). تعود غداً.'), (int) config('game.friendlies.per_day')));
                    }
                } else {
                    // The coins with the match, in the same write: no friendly unpaid, no coins for none.
                    Wallet::pay($userId, $club->league_id, 'friendly', $coins, "friendly:{$key}", 'friendly');
                }
                $step = (int) config('game.friendlies.training_progress');
                $cap = (int) config('game.training.progress_scale') - 1;
                foreach ($played as $p) {
                    DB::table('players')->where('id', $p['id'])->where('club_id', $club->id)->update(['training_progress' => Sql::least("training_progress + {$step}", $cap)]);
                }
                $id = DB::table('friendlies')->insertGetId(['club_id' => $club->id, 'opponent_id' => $opponent->id, 'user_id' => $userId, 'seed' => $seed,
                    'goals_for' => $state['score']['home'], 'goals_against' => $state['score']['away'], 'report' => json_encode($report), 'day' => self::cairoDay(),
                    'players' => json_encode(array_map(fn ($p) => (int) $p['id'], $played)), 'idempotency_key' => $key, 'created_at' => GameClock::now()]);

                return [self::row(DB::table('friendlies')->find($id)), true];
            });
        } catch (UniqueConstraintViolationException) {
            // The same key twice at once: the other request played it.
            return [self::row(DB::table('friendlies')->where('idempotency_key', $key)->first()), false];
        }
    }

    private static function row(object $f): array
    {
        $opp = DB::table('clubs')->where('id', $f->opponent_id)->first(['id', 'name', 'code', 'master_club_id']);

        return ['id' => (int) $f->id, 'opponent' => ['id' => (int) $opp->id, 'name' => $opp->name, 'code' => $opp->code, 'crest_url' => url("/api/v1/data/clubs/{$opp->master_club_id}/crest.svg")],
            'goals_for' => (int) $f->goals_for, 'goals_against' => (int) $f->goals_against, 'report' => json_decode($f->report, true),
            'at' => Carbon::parse($f->created_at, 'UTC')->toIso8601ZuluString()];
    }

    private static function cairoDay(): string
    {
        return GameClock::now()->setTimezone('Africa/Cairo')->toDateString();
    }
}
