<?php

namespace App\League;

use Illuminate\Support\Facades\DB;

/**
 * [X62 E10] A match's shot map, from its attacks that ended in a shot (a goal, a save, a block or a miss): who shot,
 * when, the result, and where on a 100 x 100 half pitch (x from the halfway line to the goal line, y across). The
 * engine gives each attack its lane and the chance's quality; the place follows them (a big chance close in, a long
 * one from distance), spread a little by the event so two shots do not sit on one point. Read only, no engine change.
 */
class ShotMap
{
    public const RESULTS = ['goal', 'saved', 'blocked', 'missed'];

    private const DEPTH = ['big' => 90, 'normal' => 82, 'half' => 76, 'long' => 66];

    private const LANE = ['left' => 26, 'center' => 50, 'right' => 74];

    public static function of(int $matchId, int $homeId): array
    {
        return DB::table('match_events')->where('match_id', $matchId)->where('type', 'attack')->orderBy('id')->get(['id', 'minute', 'club_id', 'payload'])
            ->map(function ($e) use ($homeId) {
                $p = json_decode($e->payload, true) ?: [];
                if (! in_array($p['result'] ?? '', self::RESULTS, true)) {
                    return null;
                }
                $spread = crc32((string) $e->id);

                return ['team' => (int) $e->club_id === $homeId ? 'home' : 'away', 'minute' => (int) $e->minute, 'result' => $p['result'],
                    'quality' => $p['quality'] ?? 'normal', 'shooter' => (int) ($p['shooter'] ?? 0) ?: null,
                    'x' => (self::DEPTH[$p['quality'] ?? 'normal'] ?? 80) + ($spread % 7) - 3,
                    'y' => (self::LANE[$p['lane'] ?? 'center'] ?? 50) + intdiv($spread, 7) % 15 - 7];
            })->filter()->values()->all();
    }
}
