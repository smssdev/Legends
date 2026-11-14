<?php

namespace App\Season;

use Illuminate\Support\Facades\DB;

/**
 * A coach's career across every league [X18]: the matches with the clubs coached, the trophies (a league title
 * or a cup won), and a level from both. The home screen's profile card and the coaches' global ranking.
 */
class Career
{
    /** Seasons, matches won, drawn and lost with the clubs he coached, from his memberships. */
    public static function record(int $userId): array
    {
        $out = ['seasons' => 0, 'played' => 0, 'won' => 0, 'drawn' => 0, 'lost' => 0];
        foreach (DB::table('league_memberships')->where('user_id', $userId)->whereNotNull('club_id')->get() as $m) {
            $out['seasons']++;
            $fixtures = DB::table('fixtures')->where('season_id', $m->season_id)->where('status', 'finished')->where('is_bye', false)
                ->where('scheduled_at', '>=', $m->joined_at)->when($m->left_at, fn ($q) => $q->where('scheduled_at', '<', $m->left_at))
                ->where(fn ($q) => $q->where('home_id', $m->club_id)->orWhere('away_id', $m->club_id))->get();
            foreach ($fixtures as $f) {
                [$for, $against] = $f->home_id === $m->club_id ? [$f->home_goals, $f->away_goals] : [$f->away_goals, $f->home_goals];
                $out['played']++;
                $out[$for > $against ? 'won' : ($for < $against ? 'lost' : 'drawn')]++;
            }
        }

        $out['predicted'] = DB::table('match_predictions')->where('user_id', $userId)->where('correct', true)->count();

        return $out;
    }

    /**
     * [Sprint 64 B7] Two coaches face to face: every finished match where one held one side and the other the other (by
     * their memberships, at the match's date), from [$userId]'s side, with the last five, newest first (W, D, L).
     * Counted from the matches, no table of its own.
     */
    public static function headToHead(int $userId, int $otherId): array
    {
        $out = ['played' => 0, 'won' => 0, 'drawn' => 0, 'lost' => 0, 'last' => []];
        $theirs = DB::table('league_memberships')->where('user_id', $otherId)->whereNotNull('club_id')->get()->groupBy('season_id');
        $results = [];
        foreach (DB::table('league_memberships')->where('user_id', $userId)->whereNotNull('club_id')->get() as $m) {
            $held = $theirs->get($m->season_id);
            if (! $held) {
                continue;
            }
            $fixtures = DB::table('fixtures')->where('season_id', $m->season_id)->where('status', 'finished')->where('is_bye', false)
                ->where('scheduled_at', '>=', $m->joined_at)->when($m->left_at, fn ($q) => $q->where('scheduled_at', '<', $m->left_at))
                ->where(fn ($q) => $q->where('home_id', $m->club_id)->orWhere('away_id', $m->club_id))->get();
            foreach ($fixtures as $f) {
                $opponent = $f->home_id === $m->club_id ? $f->away_id : $f->home_id;
                $theirClub = $held->first(fn ($t) => $t->club_id === $opponent && $t->joined_at <= $f->scheduled_at && ($t->left_at === null || $t->left_at > $f->scheduled_at));
                if (! $theirClub) {
                    continue;
                }
                [$for, $against] = $f->home_id === $m->club_id ? [$f->home_goals, $f->away_goals] : [$f->away_goals, $f->home_goals];
                $r = $for > $against ? 'won' : ($for < $against ? 'lost' : 'drawn');
                $out['played']++;
                $out[$r]++;
                $results[] = [$f->scheduled_at, ['won' => 'W', 'drawn' => 'D', 'lost' => 'L'][$r]];
            }
        }
        usort($results, fn ($a, $b) => strcmp($b[0], $a[0]));
        $out['last'] = array_column(array_slice($results, 0, 5), 1);

        return $out;
    }

    /** The trophies: league titles and cups won (first places only). */
    public static function trophies(int $userId): array
    {
        $won = DB::table('titles')->where('user_id', $userId)->where('position', 1)->pluck('competition');

        return ['total' => $won->count(), 'league' => $won->filter(fn ($c) => $c === 'league')->count(), 'cup' => $won->filter(fn ($c) => $c === 'cup')->count()];
    }

    /**
     * The level from the points of a career: per win, per draw and per trophy (config game.career). Each level
     * asks step points more than the last: level 2 at step, 3 at 3 × step, 4 at 6 × step...
     */
    public static function level(array $record, array $trophies): array
    {
        $c = config('game.career');
        $xp = $record['won'] * $c['xp_win'] + $record['drawn'] * $c['xp_draw'] + $trophies['total'] * $c['xp_trophy']
            // [UP12] The right predictions of the round's winners.
            + ($record['predicted'] ?? 0) * (int) ($c['xp_prediction'] ?? 0);
        $level = 1;
        $from = 0;
        while ($xp >= $from + $level * $c['level_step']) {
            $from += $level * $c['level_step'];
            $level++;
        }
        $next = $from + $level * $c['level_step'];

        return ['level' => $level, 'xp' => $xp, 'from' => $from, 'next' => $next, 'progress_bp' => intdiv(10000 * ($xp - $from), max(1, $next - $from))];
    }
}
