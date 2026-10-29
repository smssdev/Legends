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
 * Friendlies [Sprint 20 B4; Sprint 24 B2, the owner's request 2026-10-29]: a match now against any club of the
 * league, played whole by the engine from both sheets as they stand, for game.friendlies.coins (5) taken when the
 * coach confirms, in every league, with no limit (no daily one, and outside the season's coin cap). No effect on the
 * table or the money. For each of the coach's players who played: game.friendlies.fitness more fitness (up to 100),
 * game.friendlies.training_progress on his bar (never past it: the +1 itself comes from a training session), and a
 * match played together for the chemistry. The coins and the match in one write, once by the request's key.
 * Not in the last game.friendlies.block_minutes before the club's next match, nor while it is live.
 */
class Friendlies
{
    /** What the screen shows: the price, the coach's coins, why none can be played now, and the opponents. */
    public static function view(Club $club): array
    {
        $cfg = config('game.friendlies');
        $opponents = DB::table('clubs')->leftJoin('users', 'users.id', '=', 'clubs.user_id')->where('clubs.league_id', $club->league_id)->where('clubs.id', '!=', $club->id)
            ->get(['clubs.id', 'clubs.name', 'clubs.code', 'clubs.master_club_id', 'clubs.strength_snapshot', 'users.name as coach']);
        // Recommended: the closest in strength.
        $closest = $opponents->sortBy(fn ($o) => abs($o->strength_snapshot - $club->strength_snapshot))->first()?->id;

        return ['coins' => (int) $cfg['coins'], 'balance' => $club->user_id ? Wallet::balance((int) $club->user_id) : 0, 'blocked' => self::blocked($club),
            'fitness' => (int) $cfg['fitness'],
            'training_progress_pct' => intdiv((int) $cfg['training_progress'] * 100, (int) config('game.training.progress_scale')),
            'opponents' => $opponents->sortByDesc('strength_snapshot')->values()->map(fn ($o) => ['id' => (int) $o->id, 'name' => $o->name, 'code' => $o->code,
                'crest_url' => url("/api/v1/data/clubs/{$o->master_club_id}/crest.svg"), 'strength_cp' => (int) $o->strength_snapshot, 'coach' => $o->coach, 'recommended' => $o->id === $closest])->all(),
            'recent' => DB::table('friendlies')->where('club_id', $club->id)->orderByDesc('id')->limit(5)->get()->map(fn ($f) => self::row($f))->all()];
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
        $coins = (int) config('game.friendlies.coins');
        // Before playing it: a friendly the coach cannot pay for is not played.
        if (Wallet::balance($userId) < $coins) {
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
            'played' => count($played), 'coins' => $coins];

        try {
            return DB::transaction(function () use ($club, $opponent, $userId, $seed, $state, $played, $report, $coins, $key) {
                // The coins with the match, in the same write: no friendly unpaid, no coins for none. Not a league
                // spend, so the season's coin cap does not count it (no limit, the owner's request), fair league or not.
                Wallet::post($userId, 'friendly', -$coins, "friendly:{$key}", "friendly:{$club->id}");
                $step = (int) config('game.friendlies.training_progress');
                $cap = (int) config('game.training.progress_scale') - 1;
                $fitness = (int) config('game.friendlies.fitness');
                foreach ($played as $p) {
                    DB::table('players')->where('id', $p['id'])->where('club_id', $club->id)->update(['training_progress' => Sql::least("training_progress + {$step}", $cap),
                        'fitness' => Sql::least("fitness + {$fitness}", 100)]);
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
