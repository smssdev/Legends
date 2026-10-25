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
        $xp = $record['won'] * $c['xp_win'] + $record['drawn'] * $c['xp_draw'] + $trophies['total'] * $c['xp_trophy'];
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
