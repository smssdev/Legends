<?php

namespace App\Characters;

use App\Simulator\MomentClock;

/**
 * The characters' mood [Sprint 26 B1]: what the coach on the touchline, the mascot and the assistant feel about what
 * just happened, decided here so every screen (the web, the app, Unity) only draws it. The nine moods are the owner's
 * approved draft (docs/design/legends-ui/CharactersDraft.html, README section 0). Pure: no database, no clock.
 */
final class Mood
{
    public const ALL = ['idle', 'joy', 'cheer', 'sad', 'angry', 'worried', 'think', 'surprise', 'sleep'];

    /**
     * Each side's coach after one minute: a goal for him cheers, one against saddens (late, it angers), his red
     * card angers, his injured player worries; otherwise behind worries and the rest stands calm. At full time:
     * the win is joy, the draw calm, the loss sad.
     *
     * @param  list<array<string, mixed>>  $events  the minute's events (the engine's out.events)
     * @param  array{home: int, away: int}  $score  the score after the minute
     * @param  int|array{0: int, 1: int}  $minute  the minute as the engine labels it (45+2 is [45, 2])
     * @return array{home: string, away: string}
     */
    public static function forTick(array $events, array $score, int|array $minute, int $lateMinute = 85): array
    {
        $at = is_array($minute) ? (int) $minute[0] + (int) ($minute[1] ?? 0) : $minute;
        $moods = [];
        foreach (['home', 'away'] as $side) {
            $other = $side === 'home' ? 'away' : 'home';
            $lead = (int) $score[$side] <=> (int) $score[$other];
            $mood = null;
            foreach ($events as $e) {
                $team = $e['team'] ?? null;
                $type = $e['type'] ?? '';
                if ($type === 'period' && ($e['name'] ?? '') === 'fulltime') {
                    $mood = [1 => 'joy', 0 => 'idle', -1 => 'sad'][$lead];
                } elseif ($type === 'goal') {
                    $mood = $team === $side ? 'cheer' : ($at >= $lateMinute ? 'angry' : 'sad');
                } elseif ($type === 'card' && ($e['color'] ?? '') === 'red' && $team === $side) {
                    $mood = 'angry';
                } elseif ($type === 'injury' && $team === $side && $mood === null) {
                    $mood = 'worried';
                }
            }
            // [Sprint 35 C3] A goal ruled out by VAR: anger on the side that thought it had scored, relief on the other.
            if ($mood === null && ($reason = MomentClock::varReason($events))) {
                $attack = array_values(array_filter($events, fn ($e) => ($e['type'] ?? '') === 'attack'))[0] ?? [];
                $mood = ($attack['team'] ?? null) === $side ? 'angry' : 'joy';
            }
            $moods[$side] = $mood ?? ($lead < 0 ? 'worried' : 'idle');
        }

        return $moods;
    }

    /**
     * A finished match told afterwards (the after-round window): the win is joy, a big one (by $bigMargin or more)
     * a surprise; the draw calm; the loss sad, or angry when the club also had a man sent off.
     */
    public static function forResult(int $goalsFor, int $goalsAgainst, bool $sentOff, int $bigMargin = 3): string
    {
        return match ($goalsFor <=> $goalsAgainst) {
            1 => $goalsFor - $goalsAgainst >= $bigMargin ? 'surprise' : 'joy',
            0 => 'idle',
            -1 => $sentOff ? 'angry' : 'sad',
        };
    }
}
