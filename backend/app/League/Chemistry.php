<?php

namespace App\League;

use Illuminate\Support\Facades\DB;

/**
 * The eleven's chemistry, 0..100 [X22]. Each player is linked to his two nearest team-mates on the pitch, and
 * each link is green (same nationality and the same original club, or game.chemistry.together_matches played
 * together for this club), yellow (same nationality, or from the same league) or red. The chemistry is the
 * mean of the links' values. The engine reads only the number; the lineup screen draws the links.
 * Nothing secret: it is the eleven's own, and the rival sees only the eleven and the score of a match.
 */
class Chemistry
{
    /** @return array{score: int, links: list<array{a: int, b: int, color: string}>} */
    public static function of(int $clubId, array $starters, array $slots): array
    {
        $ids = array_values(array_filter($starters));
        if (count($ids) < 2) {
            return ['score' => 0, 'links' => []];
        }
        $info = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->join('master_clubs', 'master_clubs.id', '=', 'master_players.master_club_id')
            ->whereIn('players.id', $ids)
            ->get(['players.id', 'master_players.nationality', 'master_players.master_club_id', 'master_clubs.league_name'])
            ->mapWithKeys(fn ($r) => [(int) $r->id => ['nat' => (string) $r->nationality, 'club' => (int) $r->master_club_id, 'league' => (string) $r->league_name]])
            ->all();

        return self::score($starters, $slots, $info, self::together($clubId, $ids));
    }

    /**
     * The pure part: the links of the eleven on these slots and the chemistry they make.
     *
     * @param  array<int, array{nat: string, club: int, league: string}>  $info
     * @param  array<string, int>  $together  matches played together, keyed "low-high"
     */
    public static function score(array $starters, array $slots, array $info, array $together): array
    {
        $on = [];
        foreach ($starters as $i => $id) {
            if ($id !== null && isset($slots[$i], $info[$id])) {
                $on[] = ['id' => (int) $id, 'x' => (int) $slots[$i]['x'], 'y' => (int) $slots[$i]['y']];
            }
        }
        $pairs = [];
        foreach ($on as $p) {
            $near = [];
            foreach ($on as $q) {
                if ($q['id'] !== $p['id']) {
                    $near[] = [($p['x'] - $q['x']) ** 2 + ($p['y'] - $q['y']) ** 2, $q['id']];
                }
            }
            sort($near);
            foreach (array_slice($near, 0, (int) config('game.chemistry.neighbours')) as [, $other]) {
                $pairs[min($p['id'], $other).'-'.max($p['id'], $other)] = [min($p['id'], $other), max($p['id'], $other)];
            }
        }
        ksort($pairs);
        $values = config('game.chemistry.link_value');
        $links = [];
        $sum = 0;
        foreach ($pairs as $key => [$a, $b]) {
            $color = self::color($info[$a], $info[$b], $together[$key] ?? 0);
            $links[] = ['a' => $a, 'b' => $b, 'color' => $color];
            $sum += (int) $values[$color];
        }

        return ['score' => $links ? intdiv($sum, count($links)) : 0, 'links' => $links];
    }

    private static function color(array $a, array $b, int $together): string
    {
        $nation = $a['nat'] !== '' && $a['nat'] === $b['nat'];
        if (($nation && $a['club'] === $b['club']) || $together >= (int) config('game.chemistry.together_matches')) {
            return 'green';
        }

        return $nation || ($a['league'] !== '' && $a['league'] === $b['league']) ? 'yellow' : 'red';
    }

    /** How many of this club's matches each pair of the eleven played in together. */
    private static function together(int $clubId, array $ids): array
    {
        $wanted = array_flip($ids);
        $out = [];
        foreach (DB::table('match_stats')->where('club_id', $clubId)->pluck('players') as $json) {
            $played = [];
            foreach (json_decode($json, true) ?? [] as $p) {
                if (($p['played'] ?? false) && isset($wanted[(int) $p['id']])) {
                    $played[] = (int) $p['id'];
                }
            }
            sort($played);
            foreach ($played as $i => $a) {
                foreach (array_slice($played, $i + 1) as $b) {
                    $out["{$a}-{$b}"] = ($out["{$a}-{$b}"] ?? 0) + 1;
                }
            }
        }

        return $out;
    }
}
