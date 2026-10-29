<?php

namespace App\League;

/**
 * The league news' formulas [Sprint 20 S3, written by us at the owner's request, 2026-10-29]: the round's best
 * matches, its player and its coach. Pure and in whole numbers; every weight is in game.press.news.
 *
 * - A match: its goals; a draw with goals or a one-goal game (close to the end); a surprise (the winner, or a side
 *   that drew, was clearly weaker on paper); late goals that changed the result; a comeback; and its red cards.
 * - A player: his rating (6.00 = 600), his goals and assists, a clean sheet for a keeper or a defender, and his
 *   side's result. A great player on a losing side can still be the player of the round.
 * - A coach: a win (or a draw against a clearly stronger side), its margin up to a cap, how much weaker his side
 *   was on paper, an away result and a clean sheet. A coach who lost is never the coach of the round.
 */
class NewsFormulas
{
    /**
     * @param  array{home_goals: int, away_goals: int, home_strength: int, away_strength: int}  $m
     * @param  list<array{minute: int, side: string}>  $goals  the goals in order (side: home or away)
     */
    public static function match(array $m, array $goals, int $reds, array $w): int
    {
        [$h, $a] = [$m['home_goals'], $m['away_goals']];
        $diff = abs($h - $a);
        $score = ($h + $a) * $w['goal'];
        $score += $diff === 0 ? ($h > 0 ? $w['draw'] : 0) : ($diff === 1 ? $w['one_goal'] : 0);
        $gap = $m['home_strength'] - $m['away_strength'];   // > 0: the home side was stronger
        if ($diff > 0) {
            $loserStronger = $h > $a ? -$gap : $gap;
            $score += $loserStronger >= $w['upset_gap'] ? $w['upset'] : 0;
        } elseif (abs($gap) >= $w['upset_gap']) {
            $score += $w['upset_draw'];
        }
        $score += min($w['late_max'], self::lateTurns($goals, $w['late_minute'])) * $w['late_goal'];
        $score += self::comeback($goals, $h <=> $a) ? $w['comeback'] : 0;

        return $score + $reds * $w['red'];
    }

    /** Late goals (from late_minute) that changed the result: an equaliser or a winner. */
    public static function lateTurns(array $goals, int $from): int
    {
        $n = 0;
        $score = ['home' => 0, 'away' => 0];
        foreach ($goals as $g) {
            $before = $score['home'] <=> $score['away'];
            $score[$g['side']]++;
            // From level to ahead, or from behind to level.
            if ($g['minute'] >= $from && ($before === 0 || ($score['home'] <=> $score['away']) === 0)) {
                $n++;
            }
        }

        return $n;
    }

    /** The winner was behind at some point. $result: 1 home won, -1 away won, 0 a draw (never a comeback). */
    public static function comeback(array $goals, int $result): bool
    {
        if ($result === 0) {
            return false;
        }
        $score = ['home' => 0, 'away' => 0];
        foreach ($goals as $g) {
            $score[$g['side']]++;
            if (($score['home'] <=> $score['away']) === -$result) {
                return true;
            }
        }

        return false;
    }

    /** @param array{rating: int, goals: int, assists: int, line: string, conceded: int, result: int} $p  result: 1 won, 0 drew, -1 lost */
    public static function player(array $p, array $w): int
    {
        $clean = $p['conceded'] === 0 && in_array($p['line'], ['gk', 'def'], true);

        return $p['rating'] + $p['goals'] * $w['goal'] + $p['assists'] * $w['assist'] + ($clean ? $w['clean_sheet'] : 0)
            + ($p['result'] === 1 ? $w['win'] : ($p['result'] === 0 ? $w['draw'] : 0));
    }

    /**
     * The coach's result, or null when it cannot make him the coach of the round (a defeat, or a draw against a side
     * not clearly stronger).
     *
     * @param  array{for: int, against: int, strength: int, opponent_strength: int, away: bool}  $c
     */
    public static function coach(array $c, array $w): ?int
    {
        $gap = $c['opponent_strength'] - $c['strength'];   // > 0: his side was weaker
        if ($c['for'] < $c['against'] || ($c['for'] === $c['against'] && $gap < $w['upset_gap'])) {
            return null;
        }
        $won = $c['for'] > $c['against'];

        return ($won ? $w['win'] + min($w['margin_max'], $c['for'] - $c['against']) * $w['margin'] : $w['draw'])
            + intdiv(max(0, $gap), $w['gap_per_point']) + ($c['away'] ? $w['away'] : 0) + ($c['against'] === 0 ? $w['clean_sheet'] : 0);
    }
}
