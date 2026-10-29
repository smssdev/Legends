<?php

namespace App\Season;

use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 25] The coach's rating: points that rise with a win, move a little with a draw and fall with a loss, in
 * every league and cup match of the clubs he coached, weighed by the opponent's strength (game.rating). Beating a
 * stronger side earns more, losing to a weaker one costs more, and a draw with a stronger side is a gain while one
 * with a weaker side is a small loss. Trophies add their points. The points place the coach in a tier and its
 * division, from the prospect to the legend; a tier once reached is kept, so a bad run costs points but never the tier.
 *
 * Worked out from the finished fixtures and the titles each time, like the career's record, so it needs no table
 * and is the same for every coach whenever it is read.
 */
class CoachRating
{
    /**
     * A match's points: its base by result, per_step for each step the opponent was stronger (less for each step
     * weaker), away for a result away that is not a loss, and big_win for a wide win.
     *
     * @param  array{for: int, against: int, strength: int, opponent_strength: int, away: bool}  $m
     */
    public static function delta(array $m, array $w): int
    {
        $result = $m['for'] > $m['against'] ? 'win' : ($m['for'] < $m['against'] ? 'loss' : 'draw');
        // Truncated toward zero, so the same gap counts the same either way.
        $steps = max(-$w['max_steps'], min($w['max_steps'], intdiv($m['opponent_strength'] - $m['strength'], $w['step_cp'])));
        $points = $w[$result] + $steps * $w['per_step'][$result];
        if ($result !== 'loss' && $m['away']) {
            $points += $w['away'];
        }
        if ($result === 'win' && $w['big_margin'] <= $m['for'] - $m['against']) {
            $points += $w['big_win'];
        }

        return $points;
    }

    /** A trophy's points by its competition and position (nothing for a place without points). */
    public static function trophy(string $competition, int $position, array $w): int
    {
        return (int) ($w['trophies'][$competition][$position] ?? 0);
    }

    /**
     * The points after each change in order: never below the start of the highest tier reached, nor below zero.
     *
     * @param  list<int>  $deltas
     * @return array{points: int, peak: int, applied: list<int>} applied: what each change truly moved
     */
    public static function apply(array $deltas, array $w): array
    {
        $points = 0;
        $floor = 0;
        $peak = 0;
        $applied = [];
        foreach ($deltas as $d) {
            $next = max($floor, $points + $d);
            $applied[] = $next - $points;
            $points = $next;
            $peak = max($peak, $points);
            $floor = self::tier($points, $w)['min'];
        }

        return ['points' => $points, 'peak' => $peak, 'applied' => $applied];
    }

    /**
     * The tier of these points: its key, its division (3 = III, the first, to 1 = I; none for the last tier), where
     * the tier starts, where the next division or tier starts, and the way there in basis points.
     */
    public static function tier(int $points, array $w): array
    {
        $tiers = $w['tiers'];
        $keys = array_keys($tiers);
        $i = 0;
        foreach ($keys as $n => $key) {
            if ($points >= $tiers[$key]) {
                $i = $n;
            }
        }
        $key = $keys[$i];
        $min = $tiers[$key];
        if ($i === count($keys) - 1) {
            return ['key' => $key, 'rank' => $i + 1, 'division' => null, 'min' => $min, 'from' => $min, 'next' => null, 'progress_bp' => 10000];
        }
        $span = $tiers[$keys[$i + 1]] - $min;
        // The highest division whose start the points reached (the starts rounded down, like the next ones).
        $d = 0;
        while ($d < $w['divisions'] - 1 && $points >= $min + intdiv($span * ($d + 1), $w['divisions'])) {
            $d++;
        }
        $from = $min + intdiv($span * $d, $w['divisions']);
        $next = $min + intdiv($span * ($d + 1), $w['divisions']);

        return ['key' => $key, 'rank' => $i + 1, 'division' => $w['divisions'] - $d, 'min' => $min, 'from' => $from, 'next' => $next,
            'progress_bp' => intdiv(10000 * ($points - $from), max(1, $next - $from))];
    }

    /**
     * The coach's rating now: the points, the tier, the highest points ever, and the latest changes (newest first)
     * with their match or trophy.
     */
    public static function of(int $userId): array
    {
        $w = config('game.rating');
        $changes = [];
        foreach (DB::table('league_memberships')->where('user_id', $userId)->whereNotNull('club_id')->get() as $m) {
            $fixtures = DB::table('fixtures')->where('season_id', $m->season_id)->where('status', 'finished')->where('is_bye', false)
                ->where('scheduled_at', '>=', $m->joined_at)->when($m->left_at, fn ($q) => $q->where('scheduled_at', '<', $m->left_at))
                ->where(fn ($q) => $q->where('home_id', $m->club_id)->orWhere('away_id', $m->club_id))->get();
            $clubs = DB::table('clubs')->whereIn('id', $fixtures->pluck('home_id')->merge($fixtures->pluck('away_id'))->unique())->get(['id', 'name', 'strength_snapshot'])->keyBy('id');
            foreach ($fixtures as $f) {
                $home = $f->home_id === $m->club_id;
                $opponent = $clubs[$home ? $f->away_id : $f->home_id];
                [$for, $against] = $home ? [(int) $f->home_goals, (int) $f->away_goals] : [(int) $f->away_goals, (int) $f->home_goals];
                $changes[] = ['at' => Carbon::parse($f->scheduled_at, 'UTC'), 'kind' => 'match', 'competition' => $f->competition,
                    'result' => $for > $against ? 'win' : ($for < $against ? 'loss' : 'draw'), 'for' => $for, 'against' => $against, 'opponent' => $opponent->name,
                    'delta' => self::delta(['for' => $for, 'against' => $against, 'strength' => (int) $clubs[$m->club_id]->strength_snapshot,
                        'opponent_strength' => (int) $opponent->strength_snapshot, 'away' => ! $home], $w)];
            }
        }
        foreach (DB::table('titles')->where('user_id', $userId)->get() as $t) {
            if ($points = self::trophy($t->competition, (int) $t->position, $w)) {
                $changes[] = ['at' => Carbon::parse($t->created_at, 'UTC'), 'kind' => 'trophy', 'competition' => $t->competition, 'position' => (int) $t->position, 'delta' => $points];
            }
        }
        usort($changes, fn ($a, $b) => $a['at']->getTimestamp() <=> $b['at']->getTimestamp());
        $run = self::apply(array_column($changes, 'delta'), $w);
        $recent = [];
        foreach (array_reverse(array_slice(array_keys($changes), -$w['recent'])) as $i) {
            $c = $changes[$i];
            $recent[] = ['kind' => $c['kind'], 'competition' => $c['competition'], 'delta' => $run['applied'][$i], 'at' => $c['at']->toIso8601ZuluString()]
                + ($c['kind'] === 'match' ? ['result' => $c['result'], 'for' => $c['for'], 'against' => $c['against'], 'opponent' => $c['opponent'], 'position' => null]
                    : ['result' => null, 'for' => null, 'against' => null, 'opponent' => null, 'position' => $c['position']]);
        }

        return ['points' => $run['points'], 'peak' => $run['peak'], 'tier' => self::tier($run['points'], $w), 'recent' => $recent];
    }

    /** The tiers in order, with the points each starts at: the ladder the screen draws. */
    public static function ladder(): array
    {
        $tiers = config('game.rating.tiers');

        return array_map(fn ($key, $n) => ['key' => $key, 'rank' => $n + 1, 'min' => $tiers[$key]], array_keys($tiers), array_keys(array_keys($tiers)));
    }
}
