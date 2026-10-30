<?php

namespace App\League;

use App\Characters\Mood;
use App\Models\Club;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * The after-round window [Sprint 20 B3, W7]: the club's finished matches its coach has not seen (live, the report,
 * the replay or this window), the newest first, from the last game.after_round.days days and at most
 * game.after_round.max. Each one: the score, the goals, the man of the match, the coins it paid, and what it
 * changed in the coach's squad (an injury, a red card). "Skip" marks them all seen.
 */
class MissedMatches
{
    public static function of(Club $club, int $userId): array
    {
        $since = GameClock::now()->subDays((int) config('game.after_round.days'));
        $rows = DB::table('matches')->join('fixtures', 'fixtures.id', '=', 'matches.fixture_id')
            ->where('matches.status', 'finished')->where('fixtures.status', 'finished')->where('fixtures.scheduled_at', '>=', $since)
            ->where(fn ($q) => $q->where('fixtures.home_id', $club->id)->orWhere('fixtures.away_id', $club->id))
            ->whereNotExists(fn ($q) => $q->select(DB::raw(1))->from('seen_matches')->whereColumn('seen_matches.match_id', 'matches.id')->where('seen_matches.user_id', $userId))
            ->orderByDesc('fixtures.scheduled_at')->limit((int) config('game.after_round.max'))
            ->get(['matches.id', 'fixtures.id as fixture_id', 'fixtures.competition', 'fixtures.round', 'fixtures.home_id', 'fixtures.away_id', 'fixtures.home_goals', 'fixtures.away_goals', 'fixtures.scheduled_at']);
        if ($rows->isEmpty()) {
            return [];
        }
        $clubs = DB::table('clubs')->whereIn('id', $rows->pluck('home_id')->merge($rows->pluck('away_id')))->get(['id', 'name', 'code', 'master_club_id'])->keyBy('id');
        $events = DB::table('match_events')->whereIn('match_id', $rows->pluck('id'))->whereIn('type', ['goal', 'card', 'injury'])->orderBy('id')->get()->groupBy('match_id');
        $stats = DB::table('match_stats')->whereIn('match_id', $rows->pluck('id'))->get()->groupBy('match_id');
        $names = [];
        foreach ($events->flatten(1) as $e) {
            $names[] = $e->player_id;
        }
        foreach ($stats->flatten(1) as $s) {
            foreach (json_decode($s->players, true) as $p) {
                $names[] = $p['id'];
            }
        }
        $names = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->whereIn('players.id', array_filter(array_unique($names)))->pluck('master_players.name', 'players.id');
        $coins = DB::table('wallet_transactions')->where('user_id', $userId)->whereIn('reference', $rows->map(fn ($r) => "fixture:{$r->fixture_id}"))->pluck('amount', 'reference');
        $card = fn ($id) => ['id' => (int) $id, 'name' => $clubs[$id]->name, 'code' => $clubs[$id]->code, 'crest_url' => url("/api/v1/data/clubs/{$clubs[$id]->master_club_id}/crest.svg")];

        return $rows->map(function ($r) use ($club, $events, $stats, $names, $coins, $card) {
            $home = (int) $r->home_id === $club->id;
            [$for, $against] = $home ? [(int) $r->home_goals, (int) $r->away_goals] : [(int) $r->away_goals, (int) $r->home_goals];
            $own = $events[$r->id] ?? collect();
            $best = null;
            foreach ($stats[$r->id] ?? [] as $s) {
                foreach (json_decode($s->players, true) as $p) {
                    if (! empty($p['played']) && (! $best || $p['rating'] > $best['rating'])) {
                        $best = ['id' => (int) $p['id'], 'name' => $names[$p['id']] ?? null, 'rating' => (int) $p['rating'], 'mine' => (int) $s->club_id === $club->id];
                    }
                }
            }

            return ['match_id' => (int) $r->id, 'competition' => $r->competition, 'round' => (int) $r->round, 'venue' => $home ? 'home' : 'away',
                'at' => Carbon::parse($r->scheduled_at, 'UTC')->toIso8601ZuluString(), 'home' => $card($r->home_id), 'away' => $card($r->away_id),
                'home_goals' => (int) $r->home_goals, 'away_goals' => (int) $r->away_goals, 'result' => $for <=> $against,
                'goals' => $own->where('type', 'goal')->map(fn ($e) => ['minute' => (int) $e->minute, 'side' => (int) $e->club_id === (int) $r->home_id ? 'home' : 'away', 'scorer' => $names[$e->player_id] ?? null])->values()->all(),
                'man_of_the_match' => $best,
                'coins' => (int) ($coins["fixture:{$r->fixture_id}"] ?? 0),
                // What changed in my squad: my injured and sent-off players.
                'changes' => $changes = $own->filter(fn ($e) => (int) $e->club_id === $club->id && ($e->type === 'injury' || ($e->type === 'card' && (json_decode($e->payload, true)['color'] ?? null) === 'red')))
                    ->map(fn ($e) => ['kind' => $e->type === 'injury' ? 'injury' : 'red', 'player' => $names[$e->player_id] ?? null])->values()->all(),
                // [Sprint 26 B2] The mascot's mood in the window.
                'mood' => Mood::forResult($for, $against, in_array('red', array_column($changes, 'kind'), true), (int) config('game.characters.big_margin'))];
        })->all();
    }

    /** Seen: by the window's "skip", or by opening the match, its report or its replay. */
    public static function seen(int $userId, array $matchIds): void
    {
        $now = GameClock::now();
        DB::table('seen_matches')->insertOrIgnore(array_map(fn ($id) => ['user_id' => $userId, 'match_id' => (int) $id, 'seen_at' => $now], array_values(array_unique($matchIds))));
    }
}
