<?php

namespace App\Simulator;

use App\Engine\SeededRandom;

/**
 * The text commentary [PLAN 2.21, Sprint 20 B1]: a display layer after the engine. Each event of a minute gets
 * one Arabic line from the template table (resources/commentary/ar.php), picked by its context (the result, the
 * chance, the score, the minute) and by the match's seed and the minute, so the same minute always reads the
 * same, live, in the replay and in the app. It reads the public events and the names only: never a side's
 * tactics, so the line is the same for both coaches and travels in the broadcast.
 *
 * Placeholders: {p} the main player, {q} the second one (assist, keeper, defender, the one going off),
 * {A} the club the moment belongs to, {B} the other club, {n} a formation, {d} a number of minutes in words,
 * {s} the score from {A}'s side.
 */
class Commentary
{
    private const STREAM = 17;

    private static ?array $table = null;

    public static function table(): array
    {
        return self::$table ??= require resource_path('commentary/ar.php');
    }

    /** The minute's output with a 'text' on every event that has a line. */
    public static function annotate(array $state, array $out): array
    {
        $rng = SeededRandom::forTick($state['seed'], $out['tick'], self::STREAM);
        $minute = is_array($out['minute']) ? $out['minute'][0] : (int) $out['minute'];
        // The goal's attack tells how it came (a header, a counter) to the goal's own line.
        $attack = null;
        foreach ($out['events'] as $i => $e) {
            if ($e['type'] === 'attack') {
                $attack = $e;
            }
            $text = self::line($state, $e, $attack, $minute, $out['score'], $rng);
            if ($text !== null) {
                $out['events'][$i]['text'] = $text;
            }
        }

        return $out;
    }

    private static function line(array $state, array $e, ?array $attack, int $minute, array $score, SeededRandom $rng): ?string
    {
        $side = $e['team'] ?? null;
        $other = $side === 'home' ? 'away' : 'home';
        $name = fn (?string $s, $id) => $s ? self::player($state, $s, $id) : '';
        $vars = ['{A}' => $side ? $state['teams'][$side]['club']['name'] : '', '{B}' => $side ? $state['teams'][$other]['club']['name'] : ''];
        $keys = [];

        switch ($e['type']) {
            case 'attack':
                $result = $e['result'];
                if (in_array($result, ['goal', 'penalty', 'foul'], true)) {
                    return null; // their own events tell them
                }
                $vars['{p}'] = $name($side, ($e['shooter'] ?? 0) ?: (($e['creator'] ?? 0) ?: (($e['receiver'] ?? 0) ?: ($e['carrier'] ?? 0))));
                $vars['{q}'] = $result === 'saved' ? $name($other, $e['keeper'] ?? null) : $name($other, $e['defender'] ?? null);
                $quality = $e['quality'] ?? '';
                if (in_array($result, ['saved', 'missed', 'blocked'], true)) {
                    if ($e['counter'] ?? false) {
                        $keys[] = "attack.{$result}.counter";
                    }
                    if ($quality) {
                        $keys[] = "attack.{$result}.{$quality}";
                    }
                } elseif ($result === 'lost') {
                    $keys[] = count($e['phases'] ?? []) === 1 ? 'attack.lost.build' : 'attack.lost.late';
                } elseif ($result === 'cleared') {
                    $keys[] = ($e['counter'] ?? false) ? 'attack.cleared.counter' : 'attack.cleared.'.($e['plan'] ?? 'passing');
                }
                $keys[] = "attack.{$result}";
                break;

            case 'goal':
                $vars['{p}'] = $name($side, $e['scorer'] ?? null);
                $vars['{q}'] = $name($side, $e['assist'] ?? null);
                $after = $e['score'] ?? $score;
                $vars['{s}'] = $after[$side].' - '.$after[$other];
                $context = self::scoreContext($after, $side);
                if (($e['kind'] ?? 'open') !== 'open') {
                    // The penalty or the free kick has its own line; this one tells what it means.
                    $keys[] = "score.{$context}";
                    break;
                }
                $goals = self::goalsOf($state, $side, $e['scorer'] ?? null);
                if ($minute >= 85 && in_array($context, ['equaliser', 'lead'], true)) {
                    $keys[] = "goal.late.{$context}";
                }
                if ($goals === 3) {
                    $keys[] = 'goal.hattrick';
                } elseif ($goals === 2) {
                    $keys[] = 'goal.brace';
                }
                if ($minute <= 5) {
                    $keys[] = 'goal.early';
                }
                $keys[] = "goal.{$context}";
                if (($attack['quality'] ?? '') === 'header') {
                    $keys[] = 'goal.header';
                }
                if ($attack['counter'] ?? false) {
                    $keys[] = 'goal.counter';
                }
                // A goal reads its context first; how it came, when the context has nothing to say.
                $keys = [...self::shuffled($keys, $rng), 'goal'];
                if (! ($e['assist'] ?? null)) {
                    $keys = array_map(fn ($k) => isset(self::table()[$k.'.solo']) ? $k.'.solo' : $k, $keys);
                }
                break;

            case 'card':
                $vars['{p}'] = $name($side, $e['player'] ?? null);
                $keys[] = ($e['second_yellow'] ?? false) ? 'card.second_yellow' : 'card.'.($e['color'] ?? 'yellow');
                break;

            case 'foul':
                if ($e['penalty'] ?? false) {
                    return null;
                }
                $vars['{p}'] = $name($side, $e['player'] ?? null);
                $vars['{q}'] = $name($other, $e['victim'] ?? null);
                $keys[] = 'foul';
                break;

            case 'penalty':
            case 'free_kick':
                $vars['{p}'] = $name($side, $e['taker'] ?? null);
                $vars['{q}'] = $name($other, $e['keeper'] ?? null);
                $keys[] = $e['type'].(($e['scored'] ?? false) ? '.scored' : '.missed');
                break;

            case 'corner':
                $vars['{p}'] = $name($side, $e['taker'] ?? null);
                $keys[] = ($e['won'] ?? false) ? 'corner.won' : 'corner';
                break;

            case 'injury':
                $vars['{p}'] = $name($side, $e['player'] ?? null);
                $keys[] = 'injury';
                break;

            case 'sub':
                $vars['{p}'] = $name($side, $e['in'] ?? null);
                $vars['{q}'] = $name($side, $e['out'] ?? null);
                if (($e['reason'] ?? null) === 'injury') {
                    $keys[] = 'sub.injury';
                } elseif ($minute >= 75) {
                    $keys[] = 'sub.late';
                }
                $keys[] = 'sub';
                break;

            case 'action':
                // A tactics order says only that it changed: never what (the other coach reads this line too).
                $type = $e['action']['type'] ?? null;
                if ($type === 'formation') {
                    $vars['{n}'] = (string) ($e['action']['formation'] ?? '');
                    $keys[] = str_starts_with($vars['{n}'], 'custom:') || $vars['{n}'] === '' ? 'action.shape' : 'action.formation';
                } elseif ($type === 'tactics') {
                    $keys[] = 'action.tactics';
                } else {
                    return null;
                }
                break;

            case 'stoppage':
                $vars['{d}'] = self::minutes((int) ($e['added'] ?? 0));
                $keys[] = ($e['added'] ?? 0) >= 5 ? 'stoppage.long' : 'stoppage';
                break;

            case 'period':
                $p = $e['name'] ?? '';
                $final = $e['score'] ?? $score;
                if (in_array($p, ['halftime', 'fulltime'], true)) {
                    $diff = $final['home'] - $final['away'];
                    if ($diff === 0) {
                        $keys[] = "period.{$p}.draw";
                    } else {
                        $lead = $diff > 0 ? 'home' : 'away';
                        $vars['{A}'] = $state['teams'][$lead]['club']['name'];
                        $vars['{B}'] = $state['teams'][$lead === 'home' ? 'away' : 'home']['club']['name'];
                        $vars['{s}'] = max($final['home'], $final['away']).' - '.min($final['home'], $final['away']);
                        if (abs($diff) >= 3) {
                            $keys[] = "period.{$p}.big";
                        }
                        $keys[] = "period.{$p}.lead";
                    }
                } else {
                    $keys[] = "period.{$p}";
                }
                break;

            case 'shootout':
                $s = $e['score'] ?? ['home' => 0, 'away' => 0];
                $win = $s['home'] >= $s['away'] ? 'home' : 'away';
                $vars['{A}'] = $state['teams'][$win]['club']['name'];
                $vars['{B}'] = $state['teams'][$win === 'home' ? 'away' : 'home']['club']['name'];
                $vars['{s}'] = max($s['home'], $s['away']).' - '.min($s['home'], $s['away']);
                $keys[] = 'shootout';
                break;

            default:
                return null;
        }

        foreach ($keys as $key) {
            $lines = self::table()[$key] ?? null;
            if ($lines) {
                // "لـ" before a name with the article joins it: للنصر, not لـالنصر.
                return preg_replace('/لـال/u', 'لل', strtr($lines[$rng->int(count($lines))], $vars));
            }
        }

        return null;
    }

    /** What the goal did to the score, from the scorer's side. */
    private static function scoreContext(array $after, string $side): string
    {
        $other = $side === 'home' ? 'away' : 'home';
        $diff = $after[$side] - $after[$other];

        return match (true) {
            $after[$side] + $after[$other] === 1 => 'first',
            $diff === 0 => 'equaliser',
            $diff === 1 => 'lead',
            $diff > 1 => 'extend',
            default => 'reduce',
        };
    }

    /** Minutes as Arabic counts them: one, two, three to ten, more. */
    private static function minutes(int $n): string
    {
        return match (true) {
            $n === 1 => 'دقيقة واحدة',
            $n === 2 => 'دقيقتان',
            $n <= 10 => "{$n} دقائق",
            default => "{$n} دقيقة",
        };
    }

    private static function goalsOf(array $state, string $side, $id): int
    {
        foreach ($state['teams'][$side]['players'] as $p) {
            if ($p['id'] === $id) {
                return (int) $p['st']['goals'];
            }
        }

        return 0;
    }

    private static function player(array $state, string $side, $id): string
    {
        foreach ($state['teams'][$side]['players'] as $p) {
            if ($p['id'] === $id) {
                return $p['name'];
            }
        }

        return '';
    }

    /** The context keys in a seeded order, so a brace that is also an equaliser reads one or the other. */
    private static function shuffled(array $keys, SeededRandom $rng): array
    {
        $specific = array_values(array_filter($keys, fn ($k) => str_starts_with($k, 'goal.late') || $k === 'goal.hattrick'));
        $rest = array_values(array_diff($keys, $specific));
        for ($i = count($rest) - 1; $i > 0; $i--) {
            $j = $rng->int($i + 1);
            [$rest[$i], $rest[$j]] = [$rest[$j], $rest[$i]];
        }

        return [...$specific, ...$rest];
    }
}
