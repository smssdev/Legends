<?php

namespace App\Simulator;

use App\Engine\Formations;
use App\Engine\MatchSetup;
use App\Engine\SeededRandom;

/**
 * Turns one Tick of engine events into its Keyframes (docs/MATCH_VIEW.md 4.3, terms in README 7.7):
 * every player's position and the ball (with height) at 6 moments of the
 * minute (10 in a minute with a chance, a corner or a goal, Sprint 32 R4). Clients only interpolate RenderFrames between them, so the web app and the
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

    /** [Sprint 32 R4] A minute with a chance, a corner or a goal has more Keyframes: its play is drawn closer. */
    public const FRAMES_BUSY = 10;

    private const LANES = ['left' => 140, 'center' => 340, 'right' => 540];

    /**
     * @param  array  $ball  [x, y] where the previous minute ended
     * @return array{frames: list<array>, ball: array{0: int, 1: int}}
     */
    public static function frames(array $state, array $out, array $ball): array
    {
        $rng = SeededRandom::forTick($state['seed'], $out['tick'], 9);
        // Each waypoint: x, y, height, the side on the ball, and what happens there [Sprint 33 B1, B2]: a pass
        // reaching a player ('pass' and the attack's phases), a shot's end ('end'), a free kick or a penalty taken
        // from its spot ('fk', 'pen') and flying at goal ('kick'), or the kick-off ('kickoff').
        $path = [[...$ball, 0, null, 'start']];
        foreach ($out['events'] as $e) {
            if ($e['type'] === 'attack') {
                array_push($path, ...self::attackPath($e, $rng));
            } elseif ($e['type'] === 'corner') {
                $dir = $e['team'] === 'home' ? 1 : -1;
                $path[] = [self::wx(1040, $dir), $rng->chance(5000) ? 20 : 660, 0, $e['team'], 'corner', $e['taker'] ?? null];
                $path[] = [self::wx(990, $dir), 340, 25, $e['team'], 'pass'];
            } elseif ($e['type'] === 'free_kick' || $e['type'] === 'penalty') {
                // [B2] The kick from its spot (a free kick around 22 m out, a penalty from the spot), then at goal.
                $dir = $e['team'] === 'home' ? 1 : -1;
                $y = fn (int $v) => $dir === 1 ? $v : 680 - $v;
                $pen = $e['type'] === 'penalty';
                $path[] = [self::wx($pen ? 940 : 820 + $rng->int(40), $dir), $y($pen ? 340 : 270 + $rng->int(140)), 0, $e['team'], $pen ? 'pen' : 'fk', $e['taker'] ?? null];
                $path[] = $e['scored'] ?? false
                    ? [self::wx(1048, $dir), $y(310 + $rng->int(60)), $pen ? 4 : 14, $e['team'], 'kick']
                    : [self::wx(1008, $dir), $y(300 + $rng->int(80)), $pen ? 0 : 10, $e['team'], 'kick'];
            } elseif ($e['type'] === 'goal' || ($e['type'] === 'period' && in_array($e['name'], ['halftime', 'extra_time'], true))) {
                $path[] = [525, 340, 0, null, 'kickoff'];
            }
        }
        if (count($path) === 1) {
            // A quiet minute: the ball circulates around midfield.
            for ($i = 0; $i < 3; $i++) {
                $path[] = [400 + $rng->int(250), 180 + $rng->int(320), 0, $rng->chance(5000) ? 'home' : 'away', 'pass'];
            }
        }

        $busy = false;
        foreach ($out['events'] as $e) {
            $busy = $busy || in_array($e['type'], ['corner', 'goal', 'free_kick', 'penalty'], true)
                || ($e['type'] === 'attack' && in_array($e['result'] ?? null, ['goal', 'saved', 'missed', 'blocked'], true));
        }

        $frames = [];
        foreach (self::sample($path, $busy ? self::FRAMES_BUSY : self::FRAMES) as $i => [$x, $y, $z, $team, $leg]) {
            $at = self::players($state, $x, $y, $team, $leg);
            $frames[] = ['t' => $i, 'b' => [$x, $y, $z], 'p' => $at['p'], 'h' => $at['h'], 'r' => self::officials($x, $y)];
        }
        // [Sprint 32 R1] The pass goes to a player: whoever has the ball in the next Keyframe is already running to
        // where it will reach him, half the way, in this one.
        for ($i = 0; $i < count($frames) - 1; $i++) {
            $next = $frames[$i + 1]['h'];
            if ($next !== null && $next !== $frames[$i]['h'] && isset($frames[$i]['p'][$next])) {
                [$px, $py] = $frames[$i]['p'][$next];
                [$tx, $ty] = $frames[$i + 1]['p'][$next];
                $frames[$i]['p'][$next] = [$px + intdiv($tx - $px, 2), $py + intdiv($ty - $py, 2)];
            }
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
            // [Sprint 33 B4] Who has the ball there: the attack's own players, as the commentary names them.
            $who = match ($phase['n']) {
                'build' => $e['carrier'] ?? null,
                'progress', 'offside' => $e['receiver'] ?? null,
                'create' => $e['creator'] ?? null,
                'shot' => $e['shooter'] ?? null,
                default => null,
            };
            $points[] = [self::wx($ax, $dir), $y($ay), $height($phase['n']), $e['team'], $phase['n'] === 'offside' ? 'offside' : ($phase['n'] === 'shot' ? 'shot' : 'pass'), $who];
        }

        $end = match ($e['result']) {
            'goal' => [1048, 330 + $rng->int(20), 8],
            'saved' => [1005, 320 + $rng->int(40), 0],
            'missed' => [1065, $rng->chance(5000) ? 270 : 410, 12],
            'blocked' => [880, 340, 0],
            default => null,
        };
        if ($end) {
            $points[] = [self::wx($end[0], $dir), $y($end[1]), $end[2], $e['team'], 'end'];
        }

        return $points;
    }

    private static function wx(int $ax, int $dir): int
    {
        return $dir === 1 ? $ax : 1050 - $ax;
    }

    /** Evenly spaced samples along the polyline of waypoints, each with the leg it is on. */
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
                // [Sprint 33 B1] The leg of the path it is on: from what, to what, and how far along (per mille).
                ['from' => $a[4] ?? 'pass', 'to' => $b[4] ?? 'pass', 'at' => intdiv($f * 1000, $span), 'end' => [$b[0], $b[1]], 'passer' => $a[5] ?? null, 'receiver' => $b[5] ?? null],
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

    /**
     * Positions of everyone on the pitch for one ball position. Each side starts from its formation, shifted with the
     * ball. Then [Sprint 32 R2, R3]: the side on the ball runs (its forwards beyond the last line, its wide defenders
     * overlapping on the ball's flank), the other side closes up around the ball and its outfield players step
     * towards the nearest opponent, goal side; at a corner both sides crowd the box. All from the formation, the
     * players' lines and the ball: never from a side's hidden tactics.
     *
     * @return array{p: array<int|string, array{0: int, 1: int}>, h: int|string|null, sides: array<int|string, string>}
     */
    private static function players(array $state, int $bx, int $by, ?string $possession, array $leg = []): array
    {
        $to = $leg['to'] ?? 'pass';
        $at = $leg['at'] ?? 1000;
        $from = $leg['from'] ?? 'pass';
        // [Sprint 33 B2] At a set piece (arriving at its spot or just leaving it) and at the kick-off, everyone takes
        // up his place for it.
        $setPiece = (in_array($to, ['fk', 'pen'], true) && $at >= 600) ? $to : ((in_array($from, ['fk', 'pen'], true) && $at <= 250) ? $from : null);
        $kickoff = ($to === 'kickoff' && $at >= 600) || ($from === 'kickoff' && $at <= 250);
        if ($kickoff) {
            $possession = null;
        }
        $positions = [];
        $sides = [];
        $lines = [];
        $best = [];
        $corner = ($bx <= 30 || $bx >= 1020) && ($by <= 40 || $by >= 640);
        foreach (['home', 'away'] as $side) {
            $team = $state['teams'][$side];
            $slots = MatchSetup::slots($team);
            $dir = $side === 'home' ? 1 : -1;
            $attacking = $possession === $side;
            // How far the ball is up the pitch for this side (0 its own goal line, 1050 the other's).
            $ax = $dir === 1 ? $bx : 1050 - $bx;
            $n = 0;
            foreach ($team['players'] as $p) {
                if (! $p['on'] || $p['slot'] === null) {
                    continue;
                }
                $slot = $slots[$p['slot']] ?? ['x' => 300, 'y' => 340];
                $x = $dir === 1 ? $slot['x'] : 1050 - $slot['x'];
                $y = $dir === 1 ? $slot['y'] : 680 - $slot['y'];
                $line = $p['slot_line'];
                if ($line === 'gk') {
                    $x += intdiv(($bx - 525) * 6, 100);
                    $y = 340 + intdiv(($by - 340) * 25, 100);
                } elseif ($setPiece !== null && $possession !== null) {
                    // [B2] A free kick: a wall of four 9 m from the ball towards the goal, the rest of the defence in
                    // the box, the attackers along its edge. A penalty: everyone outside the box but the taker.
                    $end = $possession === 'home' ? 1 : -1;
                    $gx = $end === 1 ? 1050 : 0;
                    $spot = $n++;
                    if ($setPiece === 'pen') {
                        $x = $gx - $end * (190 + ($spot % 3) * 25 + ($attacking ? 0 : 12));
                        $y = 180 + ($spot * 41) % 320;
                    } elseif (! $attacking && $spot < 4) {
                        $len = max(1, abs($gx - $bx) + abs(340 - $by));
                        $x = $bx + intdiv(($gx - $bx) * 91, $len);
                        $y = $by + intdiv((340 - $by) * 91, $len) + ($spot - 1) * 14 - 7;
                    } elseif (! $attacking) {
                        $x = $gx - $end * (40 + ($spot % 3) * 35);
                        $y = 270 + ($spot * 29) % 150;
                    } else {
                        $x = $gx - $end * (150 + ($spot % 2) * 20);
                        $y = 230 + ($spot * 37) % 230;
                    }
                } elseif ($corner && $possession !== null) {
                    // A corner: most of both sides in the box at the corner's end, the attackers among the defenders.
                    $end = $bx >= 525 ? 1 : -1;
                    $spot = $n++;
                    $x = $end === 1 ? 990 - ($spot % 3) * 22 - ($attacking ? 0 : 8) : 60 + ($spot % 3) * 22 + ($attacking ? 0 : 8);
                    $y = 250 + ($spot * 37) % 190 + ($attacking ? 0 : 12);
                    if ($attacking && $line === 'def' && $spot % 2 === 0) {
                        // Two stay back.
                        $x = 525 + $end * 60;
                    }
                } else {
                    $x += intdiv(($bx - 525) * 45, 100) + $dir * ($possession === null ? 0 : ($attacking ? 50 : -30));
                    $y += intdiv(($by - 340) * 18, 100);
                    if ($attacking && $line === 'att' && $ax > 600) {
                        // [R2] The forwards run beyond the last line, and pull a little away from the ball across.
                        $x += $dir * intdiv(($ax - 600) * 30, 100);
                        $y += intdiv(($y - $by) * 10, 100);
                    } elseif ($attacking && $line === 'def' && $ax > 450 && abs($y - 340) > 140 && ($y - 340) * ($by - 340) > 0) {
                        // [R2] The wide defender on the ball's flank overlaps.
                        $x += $dir * 90;
                    } elseif (! $attacking && $possession !== null) {
                        // [R3] The defending side closes up around the ball across the pitch.
                        $y += intdiv(($by - $y) * 25, 100);
                    }
                }
                if ($kickoff) {
                    // [B2] The kick-off: each side in its own half.
                    $x = $dir === 1 ? min($x, 510) : max($x, 540);
                }
                $x = max(15, min(1035, $x));
                $y = max(15, min(665, $y));
                $positions[$p['id']] = [$x, $y];
                $sides[$p['id']] = $side;
                $lines[$p['id']] = $line;
            }
        }

        // [R3] Marking: away from a corner, each outfield player of the side without the ball steps a third of the way
        // towards the nearest opponent, staying goal side of him.
        if ($possession !== null && ! $corner && $setPiece === null) {
            $other = $possession === 'home' ? 'away' : 'home';
            $goalX = $other === 'home' ? 0 : 1050;
            $runners = array_keys(array_filter($sides, fn ($s) => $s === $possession));
            foreach ($positions as $id => [$x, $y]) {
                if ($sides[$id] !== $other || $lines[$id] === 'gk') {
                    continue;
                }
                $near = null;
                $nd = PHP_INT_MAX;
                foreach ($runners as $r) {
                    $d = abs($positions[$r][0] - $x) + abs($positions[$r][1] - $y);
                    if ($d < $nd) {
                        $nd = $d;
                        $near = $r;
                    }
                }
                if ($near !== null && $nd < 260) {
                    [$mx, $my] = $positions[$near];
                    $mx += $goalX === 0 ? -18 : 18;
                    $positions[$id] = [max(15, min(1035, $x + intdiv($mx - $x, 3))), max(15, min(665, $y + intdiv($my - $y, 3)))];
                }
            }
        }

        // [Sprint 33 B3] The back line of the side without the ball steps up and drops as one: its defenders level,
        // at their average depth. And an offside: the attacker caught is a step beyond that line.
        if ($possession !== null && ! $corner && $setPiece === null) {
            $other = $possession === 'home' ? 'away' : 'home';
            $back = array_keys(array_filter($sides, fn ($s, $id) => $s === $other && $lines[$id] === 'def', ARRAY_FILTER_USE_BOTH));
            if (count($back) > 1) {
                $line = intdiv(array_sum(array_map(fn ($id) => $positions[$id][0], $back)), count($back));
                foreach ($back as $id) {
                    $positions[$id][0] = $line;
                }
                if ($to === 'offside' && $at >= 400) {
                    $dirA = $possession === 'home' ? 1 : -1;
                    $near = null;
                    foreach ($positions as $id => [$x, $y]) {
                        if ($sides[$id] === $possession && $lines[$id] === 'att' && ($near === null || abs($y - $by) < abs($positions[$near][1] - $by))) {
                            $near = $id;
                        }
                    }
                    if ($near !== null) {
                        $positions[$near][0] = max(15, min(1035, $line + $dirA * 25));
                    }
                }
            }
        }

        foreach ($positions as $id => [$x, $y]) {
            $d = abs($x - $bx) + abs($y - $by);
            if ($lines[$id] !== 'gk' && (! isset($best[$sides[$id]]) || $d < $best[$sides[$id]][0])) {
                $best[$sides[$id]] = [$d, $id];
            }
        }
        $holder = null;
        // [Sprint 33 B1] A pass in flight (past the first third of its leg, to a player): no one has the ball; the
        // teammate nearest where it lands runs to meet it there, arriving with it. Before that, the passer carries it.
        // A shot, or a free kick or a penalty, once struck: in flight at goal, no one's.
        if (in_array($to, ['end', 'kick'], true) && $at > 150) {
            return ['p' => $positions, 'h' => null, 'sides' => $sides];
        }
        $flight = ! $kickoff && $setPiece === null && $at > 350 && in_array($to, ['pass', 'offside', 'shot'], true) && isset($leg['end']);
        if ($flight && $possession !== null) {
            [$ex, $ey] = $leg['end'];
            $recv = null;
            $rd = PHP_INT_MAX;
            foreach ($positions as $id => [$x, $y]) {
                $d = abs($x - $ex) + abs($y - $ey);
                if ($sides[$id] === $possession && $lines[$id] !== 'gk' && $d < $rd) {
                    $rd = $d;
                    $recv = $id;
                }
            }
            // [B4] The named receiver when he is on the pitch for the side on the ball, and near where it lands (30 m).
            $named = $leg['receiver'] ?? null;
            if ($named !== null && ($sides[$named] ?? null) === $possession && abs($positions[$named][0] - $ex) + abs($positions[$named][1] - $ey) < 300) {
                $recv = $named;
            }
            if ($recv !== null) {
                [$x, $y] = $positions[$recv];
                $positions[$recv] = [$x + intdiv(($ex - $x) * $at, 1000), $y + intdiv(($ey - $y) * $at, 1000)];
            }

            return ['p' => $positions, 'h' => null, 'sides' => $sides];
        }
        // [B4] Carrying: the named passer (or, arriving at the waypoint, its own named player), else the nearest.
        $named = $at >= 900 ? ($leg['receiver'] ?? null) : ($leg['passer'] ?? null);
        // Only one close enough (25 m) to reach the ball without a jump.
        if ($possession && $named !== null && ($sides[$named] ?? null) === $possession && ($lines[$named] ?? 'gk') !== 'gk'
            && abs($positions[$named][0] - $bx) + abs($positions[$named][1] - $by) < 250) {
            $best[$possession] = [0, $named];
        }
        if ($possession && isset($best[$possession])) {
            $holder = $best[$possession][1];
            $dir = $possession === 'home' ? 1 : -1;
            $positions[$holder] = [max(15, min(1035, $bx - $dir * 12)), max(15, min(665, $by + 6))];
            $other = $possession === 'home' ? 'away' : 'home';
            if (isset($best[$other]) && $setPiece === null) {
                $positions[$best[$other][1]] = [max(15, min(1035, $bx + $dir * 22)), max(15, min(665, $by + 18))];
            }
        }

        return ['p' => $positions, 'h' => $holder, 'sides' => $sides];
    }
}
