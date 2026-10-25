<?php

namespace App\Market;

use App\Economy\Economy;
use App\League\ClubLedger;
use App\Messages\Inbox;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * The scout [docs/features/scout.md, Sprint 26]: a paid search for players from outside the league's clubs by
 * the coach's criteria. The report comes after a 15-hour trip (scaled by the season's length) even if the coach is
 * away, with five players [X15] this club alone may buy at the pool's price until the pool is renewed; none found,
 * the money comes back.
 */
class Scout
{
    public const LINES = ['gk', 'def', 'mid', 'att'];

    /** Ask the scout. Returns the request's id. */
    public static function ask(int $clubId, array $criteria, string $key): int
    {
        return DB::transaction(function () use ($clubId, $criteria, $key) {
            $done = DB::table('scout_requests')->where('idempotency_key', $key)->value('id');
            if ($done) {
                return (int) $done;
            }
            $club = DB::table('clubs')->where('id', $clubId)->first();
            $league = DB::table('leagues')->where('id', $club->league_id)->first();
            $season = DB::table('seasons')->where('league_id', $league->id)->orderByDesc('number')->first();
            if (DB::table('scout_requests')->where('club_id', $clubId)->where('status', 'searching')->exists()) {
                throw new HttpException(409, 'الكشاف يبحث لك الآن، انتظر تقريره.');
            }
            $cost = self::cost($league->id);
            $now = GameClock::now();
            $seconds = intdiv((int) config('game.scout.hours') * 3600 * max(1, (int) $league->timer_scale), 10000);
            $id = DB::table('scout_requests')->insertGetId([
                'club_id' => $clubId, 'season_id' => $season->id, 'criteria' => json_encode($criteria), 'cost' => $cost,
                'status' => 'searching', 'finishes_at' => $now->copy()->addSeconds($seconds), 'idempotency_key' => $key,
                'created_at' => $now, 'updated_at' => $now,
            ]);
            ClubLedger::post($clubId, 'scout', -$cost, "scout:{$id}", "scout:{$id}", spend: true);

            return $id;
        });
    }

    public static function cost(int $leagueId): int
    {
        return intdiv(Economy::scale($leagueId) * (int) config('game.scout.cost_bp'), 10000);
    }

    /** Every minute: the reports whose time has come. */
    public static function due(): int
    {
        $n = 0;
        foreach (DB::table('scout_requests')->where('status', 'searching')->where('finishes_at', '<=', GameClock::now())->pluck('id') as $id) {
            $n += self::report((int) $id) ? 1 : 0;
        }

        return $n;
    }

    /** The search itself: five players from outside the league, the strongest in range first, drawn by the request. */
    public static function report(int $id): bool
    {
        return DB::transaction(function () use ($id) {
            $r = DB::table('scout_requests')->where('id', $id)->first();
            if (DB::table('scout_requests')->where('id', $id)->where('status', 'searching')->update(['updated_at' => GameClock::now()]) !== 1) {
                return false;
            }
            $club = DB::table('clubs')->where('id', $r->club_id)->first();
            $c = json_decode($r->criteria, true);
            $min = (int) ($c['min_overall'] ?? 40);
            $max = (int) ($c['max_overall'] ?? 99);
            $version = DB::table('master_players')->max('data_version');
            $candidates = DB::table('master_players')->join('master_clubs', 'master_clubs.id', '=', 'master_players.master_club_id')
                ->where('master_players.data_version', $version)
                ->whereNotIn('master_players.id', DB::table('players')->where('league_id', $club->league_id)->select('master_player_id'))
                ->whereBetween('master_players.overall', [$min, $max])
                ->when($c['line'] ?? null, fn ($q, $v) => $q->where('master_players.line', $v))
                ->when($c['position'] ?? null, fn ($q, $v) => $q->where('master_players.position', $v))
                ->when($c['max_age'] ?? null, fn ($q, $v) => $q->where('master_players.age', '<=', $v))
                ->when($c['nationality'] ?? null, fn ($q, $v) => $q->where('master_players.nationality', $v))
                ->when($c['league'] ?? null, fn ($q, $v) => $q->where('master_clubs.league_name', $v))
                ->when($c['max_value'] ?? null, fn ($q, $v) => $q->where('master_players.value', '<=', $v))
                ->orderByDesc('master_players.overall')->limit(300)->get(['master_players.id', 'master_players.overall', 'master_players.value', 'master_players.name']);
            // The strongest in range first, drawn among equals by the request, so the same search may find others.
            $picked = $candidates->sortBy(fn ($p) => [-$p->overall, crc32("{$id}:{$p->id}")])->take((int) config('game.scout.results'))->values();
            $now = GameClock::now();
            if ($picked->isEmpty()) {
                DB::table('scout_requests')->where('id', $id)->update(['status' => 'empty', 'result_player_ids' => '[]', 'updated_at' => $now]);
                ClubLedger::post($club->id, 'scout_refund', (int) $r->cost, "scout:{$id}:refund", "scout:{$id}");
                Inbox::send($club->user_id, 'scout_report', ['players' => [], 'request_id' => $id], $club->league_id, $club->id);

                return true;
            }
            $ids = [];
            foreach ($picked as $m) {
                $ids[] = DB::table('players')->insertGetId(['league_id' => $club->league_id, 'club_id' => null, 'master_player_id' => $m->id,
                    'overall' => $m->overall, 'base_value' => $m->value, 'value' => $m->value, 'in_pool' => false, 'scouted_by' => $club->id,
                    'created_at' => $now, 'updated_at' => $now]);
            }
            DB::table('scout_requests')->where('id', $id)->update(['status' => 'done', 'result_player_ids' => json_encode($ids), 'updated_at' => $now]);
            Inbox::send($club->user_id, 'scout_report', ['players' => $picked->pluck('name')->all(), 'request_id' => $id], $club->league_id, $club->id);

            return true;
        });
    }
}
