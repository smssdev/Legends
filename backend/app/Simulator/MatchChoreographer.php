<?php

namespace App\Simulator;

use App\Engine\Formations;
use App\Engine\MatchSetup;
use App\Engine\SeededRandom;

/**
 * Turns one Tick of engine events into its Keyframes (docs/MATCH_VIEW.md 4.3, terms in README 7.7):
 * every player's position and the ball (with height) at 6 moments of the
 * minute. Clients only interpolate RenderFrames between them, so the web app and the
 * Flutter app later draw exactly the same picture.
 *
 * Coordinates are decimetres: x 0..1050 (the home team attacks towards
 * 1050), y 0..680 (0 is the far touchline). Deterministic: its own random
 * stream, separate from the engine's, so drawing never changes a result.
 * Shapes are drawn from formations only, never from hidden tactics. Each Keyframe also carries the
 * officials (`r`: the referee and his two assistants, Sprint 31 D1).
 */
class MatchChoreographer
{
    public const FRAMES = 6;

    private const LANES = ['left' => 140, 'center' => 340, 'right' => 540];

    /**
     * @param  array  $ball  [x, y] where the previous minute ended
     * @return array{frames: list<array>, ball: array{0: int, 1: int}}
     */
    public static function frames(array $state, array $out, array $ball): array
    {
        $rng = SeededRandom::forTick($state['seed'], $out['tick'], 9);
        $path = [[...$ball, 0, null]];
        foreach ($out['events'] as $e) {
            if ($e['type'] === 'attack') {
                array_push($path, ...self::attackPath($e, $rng));
            } elseif ($e['type'] === 'corner') {
                $dir = $e['team'] === 'home' ? 1 : -1;
                $path[] = [self::wx(1040, $dir), $rng->chance(5000) ? 20 : 660, 0, $e['team']];
                $path[] = [self::wx(990, $dir), 340, 25, $e['team']];
            } elseif ($e['type'] === 'goal' || ($e['type'] === 'period' && in_array($e['name'], ['halftime', 'extra_time'], true))) {
                $path[] = [525, 340, 0, null];
            }
        }
        if (count($path) === 1) {
            // A quiet minute: the ball circulates around midfield.
            for ($i = 0; $i < 3; $i++) {
                $path[] = [400 + $rng->int(250), 180 + $rng->int(320), 0, $rng->chance(5000) ? 'home' : 'away'];
            }
        }

        $frames = [];
        foreach (self::sample($path, self::FRAMES) as $i => [$x, $y, $z, $team]) {
            $frames[] = ['t' => $i, 'b' => [$x, $y, $z]] + self::players($state, $x, $y, $team) + ['r' => self::officials($x, $y)];
        }
        $last = end($path);

        return ['frames' => $frames, 'ball' => [$last[0], $last[1]]];
    }

    /** Ball waypoints for one attack, in attacking coordinates converted to the pitch. */
    private static function attackPath(array $e, SeededRandom $rng): array
    {
        $dir = $e['team'] === 'home' ? 1 : -1;
        $laneY = self::LANES[$e['lane'] ?? 'center'];
        $y = fn (int $v) => $dir === 1 ? $v : 680 - $v;
        $points = [];
        $height = fn ($phase) => match (true) {
            $phase === 'progress' && in_array($e['plan'] ?? '', ['long', 'counter'], true) => 30,
            $phase === 'create' && ($e['plan'] ?? '') === 'wings' => 20,
            default => 0,
        };

        foreach ($e['phases'] as $phase) {
            [$ax, $ay] = match ($phase['n']) {
                'build' => [280 + $rng->int(100), 260 + $rng->int(160)],
                'progress' => [540 + $rng->int(120), $laneY + $rng->int(80) - 40],
                'offside' => [720, $laneY],
                'create' => [840 + $rng->int(60), ($e['plan'] ?? '') === 'wings' ? $laneY : 300 + $rng->int(80)],
                'shot', 'corner' => [900 + $rng->int(50), 280 + $rng->int(120)],
                default => [525, 340],
            };
            $points[] = [self::wx($ax, $dir), $y($ay), $height($phase['n']), $e['team']];
        }

        $end = match ($e['result']) {
            'goal' => [1048, 330 + $rng->int(20), 8],
            'saved' => [1005, 320 + $rng->int(40), 0],
            'missed' => [1065, $rng->chance(5000) ? 270 : 410, 12],
            'blocked' => [880, 340, 0],
            default => null,
        };
        if ($end) {
            $points[] = [self::wx($end[0], $dir), $y($end[1]), $end[2], $e['team']];
        }

        return $points;
    }

    private static function wx(int $ax, int $dir): int
    {
        return $dir === 1 ? $ax : 1050 - $ax;
    }

    /** Evenly spaced samples along the polyline of waypoints. */
    private static function sample(array $path, int $n): array
    {
        $lengths = [0];
        for ($i = 1; $i < count($path); $i++) {
            $lengths[] = $lengths[$i - 1] + abs($path[$i][0] - $path[$i - 1][0]) + abs($path[$i][1] - $path[$i - 1][1]) + 1;
        }
        $total = end($lengths);
        $samples = [];
        for ($k = 0; $k < $n; $k++) {
            $target = intdiv($total * ($k + 1), $n);
            $i = 1;
            while ($i < count($path) - 1 && $lengths[$i] < $target) {
                $i++;
            }
            $i = min($i, count($path) - 1);
            $span = max(1, $lengths[$i] - $lengths[$i - 1]);
            $f = max(0, min($span, $target - $lengths[$i - 1]));
            $a = $path[$i - 1];
            $b = $path[$i];
            $samples[] = [
                $a[0] + intdiv(($b[0] - $a[0]) * $f, $span),
                $a[1] + intdiv(($b[1] - $a[1]) * $f, $span),
                $b[2],
                $b[3] ?? $a[3],
            ];
        }

        return $samples;
    }

    /**
     * [Sprint 31 D1] The referee and his two assistants for one ball position: the referee on the diagonal, off the
     * ball and never in its way; the assistants outside the touchlines, each on his own half (the far one on the
     * right half, the near one on the left), level with the ball when it is in their half. Drawing only: they
     * follow the ball, never a side's shape or tactics.
     *
     * @return list<array{0: int, 1: int}> referee, far assistant, near assistant
     */
    public static function officials(int $bx, int $by): array
    {
        $low = $by > 340;
        $rx = max(40, min(1010, $bx + ($low ? -110 : 110)));
        $ry = max(60, min(620, 340 + intdiv(($by - 340) * 35, 100) + ($low ? -90 : 90)));

        return [[$rx, $ry], [max(525, min(1040, $bx)), -14], [max(10, min(525, $bx)), 694]];
    }

    /** Positions of everyone on the pitch for one ball position. */
    private static function players(array $state, int $bx, int $by, ?string $possession): array
    {
        $positions = [];
        $holder = null;
        $best = [];
        foreach (['home', 'away'] as $side) {
            $team = $state['teams'][$side];
            $slots = MatchSetup::slots($team);
            $dir = $side === 'home' ? 1 : -1;
            $attacking = $possession === $side;
            foreach ($team['players'] as $p) {
                if (! $p['on'] || $p['slot'] === null) {
                    continue;
                }
                $slot = $slots[$p['slot']] ?? ['x' => 300, 'y' => 340];
                $x = $dir === 1 ? $slot['x'] : 1050 - $slot['x'];
                $y = $dir === 1 ? $slot['y'] : 680 - $slot['y'];
                if ($p['slot_line'] === 'gk') {
                    $x += intdiv(($bx - 525) * 6, 100);
                    $y = 340 + intdiv(($by - 340) * 25, 100);
                } else {
                    $x += intdiv(($bx - 525) * 45, 100) + $dir * ($possession === null ? 0 : ($attacking ? 50 : -30));
                    $y += intdiv(($by - 340) * 18, 100);
                }
                $x = max(15, min(1035, $x));
                $y = max(15, min(665, $y));
                $positions[$p['id']] = [$x, $y];
                $d = abs($x - $bx) + abs($y - $by);
                if ($p['slot_line'] !== 'gk' && (! isset($best[$side]) || $d < $best[$side][0])) {
                    $best[$side] = [$d, $p['id']];
                }
            }
        }

        if ($possession && isset($best[$possession])) {
            $holder = $best[$possession][1];
            $dir = $possession === 'home' ? 1 : -1;
            $positions[$holder] = [max(15, min(1035, $bx - $dir * 12)), max(15, min(665, $by + 6))];
            $other = $possession === 'home' ? 'away' : 'home';
            if (isset($best[$other])) {
                $positions[$best[$other][1]] = [max(15, min(1035, $bx + $dir * 22)), max(15, min(665, $by + 18))];
            }
        }

        return ['p' => $positions, 'h' => $holder];
    }
}
