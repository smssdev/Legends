<?php

namespace App\Tournament;

use App\League\CupBracket;
use App\League\LiveDraw;
use App\League\RoundRobin;
use Random\Engine\Mt19937;
use Random\Randomizer;

/**
 * [Sprint 29] A tournament's shape from its draw, pure: teams and a seed in, the draw's steps, the groups, the rounds
 * and the knockout out. The same seed always gives the same tournament, so the draw can be replayed step by step.
 *
 *  - league: the teams drawn into slots, then a round robin (one leg or two).
 *  - groups: pots by strength (the strongest group_count teams in pot 1...); each pot drawn in turn, its i-th ball
 *    into the i-th group. A round robin in each group, the same round on the same day. The first advance_per_group
 *    go on to a knockout where a group's winner meets another group's runner-up, and two teams of one group can only
 *    meet again in the final.
 *  - knockout: the cup's bracket (CupBracket), the weakest playing a preliminary round when the count needs one.
 */
class TournamentPlan
{
    public const FORMATS = ['league', 'groups', 'knockout'];

    /**
     * @param  list<int>  $byStrength  team ids, strongest first
     * @return array{steps: list<array>, groups: array<int, int>, rounds: list<array{matches: list<array{0: int, 1: int}>, rests: list<int>}>, ties: list<array>}
     */
    public static function make(array $byStrength, int $seed, string $format, int $groupCount = 1, int $advance = 2, int $legs = 1): array
    {
        return match ($format) {
            'league' => self::league($byStrength, $seed, $legs),
            'groups' => self::groups($byStrength, $seed, $groupCount, $advance, $legs),
            'knockout' => self::knockout($byStrength, $seed),
        };
    }

    private static function league(array $teams, int $seed, int $legs): array
    {
        $order = LiveDraw::order($teams, $seed);
        $steps = array_map(fn ($id, $i) => ['type' => 'slot', 'club' => $id, 'slot' => $i + 1], $order, array_keys($order));

        return ['steps' => $steps, 'groups' => [], 'rounds' => self::robin($order, $legs), 'ties' => []];
    }

    private static function groups(array $teams, int $seed, int $groupCount, int $advance, int $legs): array
    {
        $rng = new Randomizer(new Mt19937($seed));
        $groups = [];
        $members = array_fill(1, $groupCount, []);
        $steps = [];
        foreach (array_chunk($teams, $groupCount) as $p => $pot) {
            foreach ($rng->shuffleArray($pot) as $i => $club) {
                $g = $i + 1;
                $groups[$club] = $g;
                $members[$g][] = $club;
                $steps[] = ['type' => 'group', 'club' => $club, 'pot' => $p + 1, 'group' => $g, 'position' => count($members[$g])];
            }
        }
        // Every group's round r on the same day; a smaller group rests its extra rounds.
        $rounds = [];
        foreach ($members as $list) {
            foreach (self::robin($list, $legs) as $r => $round) {
                $rounds[$r]['matches'] = array_merge($rounds[$r]['matches'] ?? [], $round['matches']);
                $rounds[$r]['rests'] = array_merge($rounds[$r]['rests'] ?? [], $round['rests']);
            }
        }

        return ['steps' => $steps, 'groups' => $groups, 'rounds' => array_values($rounds), 'ties' => self::afterGroups($groupCount, $advance)];
    }

    private static function knockout(array $teams, int $seed): array
    {
        $ties = CupBracket::draw($teams, $seed);
        $steps = [];
        foreach ($ties as $t) {
            foreach (['home', 'away'] as $side) {
                if ($t[$side] !== null) {
                    $steps[] = ['type' => 'tie', 'club' => $t[$side], 'stage' => $t['stage'], 'slot' => $t['slot'], 'side' => $side];
                }
            }
        }

        return ['steps' => $steps, 'groups' => [], 'rounds' => [], 'ties' => $ties];
    }

    /** A round robin over these teams: one leg (the first half of home and away) or both. */
    public static function robin(array $teams, int $legs): array
    {
        if (count($teams) < 2) {
            return [];
        }
        $all = RoundRobin::rounds($teams);
        $all = $legs === 2 ? $all : array_slice($all, 0, intdiv(count($all), 2));

        return array_map(fn ($r) => ['matches' => $r['matches'], 'rests' => $r['rest'] === null ? [] : [$r['rest']]], $all);
    }

    /** The group letter: 1 => A. */
    public static function letter(int $group): string
    {
        return chr(64 + $group);
    }

    /**
     * The knockout after the groups: empty ties whose sides say where they come from ("A1", "B2"), in the bracket's
     * order, each pointing at the tie its winner goes to.
     */
    public static function afterGroups(int $groupCount, int $advance): array
    {
        $size = $groupCount * $advance;
        $L = fn (int $g, int $place) => self::letter($g).$place;
        $pairs = [];
        if ($advance === 1) {
            for ($g = 1; $g <= $groupCount; $g += 2) {
                $pairs[] = [$L($g, 1), $L($g + 1, 1)];
            }
        } elseif ($groupCount === 1) {
            $pairs[] = [$L(1, 1), $L(1, 2)];
        } else {
            // Winner of one group against the runner-up of its neighbour; the two of a group in opposite halves.
            $first = $second = [];
            for ($g = 1; $g <= $groupCount; $g += 2) {
                $first[] = [$L($g, 1), $L($g + 1, 2)];
                $second[] = [$L($g + 1, 1), $L($g, 2)];
            }
            $pairs = array_merge($first, $second);
        }
        $stages = [];
        for ($s = $size; $s >= 2; $s = intdiv($s, 2)) {
            $stages[] = CupBracket::NAMES[$s];
        }
        $ties = [];
        foreach ($pairs as $i => [$home, $away]) {
            $ties[] = ['stage' => $stages[0], 'slot' => $i + 1, 'home' => null, 'away' => null, 'home_from' => $home, 'away_from' => $away, 'next' => null];
        }
        for ($j = 1; $j < count($stages); $j++) {
            $count = intdiv($size, 2 ** ($j + 1));
            for ($slot = 1; $slot <= $count; $slot++) {
                $ties[] = ['stage' => $stages[$j], 'slot' => $slot, 'home' => null, 'away' => null, 'next' => null];
            }
        }
        foreach ($ties as &$t) {
            $j = array_search($t['stage'], $stages, true);
            if ($j < count($stages) - 1) {
                $t['next'] = [$stages[$j + 1], intdiv($t['slot'] + 1, 2), $t['slot'] % 2 === 1 ? 'home' : 'away'];
            }
        }
        unset($t);

        return $ties;
    }

    /** The stages in the order they are played. */
    public static function stages(array $ties): array
    {
        return array_values(array_unique(array_column($ties, 'stage')));
    }
}
