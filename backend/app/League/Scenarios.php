<?php

namespace App\League;

use App\Models\Club;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * The pre-match scenarios [X23]: up to three plans the coach sets before the match, carried out by the server
 * when their moment comes, whether he is watching or not: trailing from a minute, a red card against us, and
 * holding a lead from a minute. Each changes the pressing, the tempo and the style, and may make one
 * substitution. They are frozen with the sheet at the lock and go in once each, as ordinary orders (so a
 * replay gives the same match). Like the pressing and the tempo, they never leave the server for the rival.
 */
class Scenarios
{
    /** Each kind with its minute: [default, earliest, latest], or null when it has none. */
    public const KINDS = [
        'trailing' => [60, 46, 85],
        'red_card' => null,
        'leading' => [75, 60, 88],
    ];

    public const TACTICS = ['pressing', 'tempo', 'style'];

    /** @return list<array{kind: string, minute: ?int, tactics: array, sub: ?array{out: int, in: int}}> */
    public static function of(Club $club): array
    {
        $json = DB::table('tactics')->where('club_id', $club->id)->value('scenarios');

        return $json ? json_decode($json, true) : [];
    }

    public static function save(Club $club, array $list): array
    {
        MatchPrep::assertOpen($club);
        $mine = DB::table('players')->where('club_id', $club->id)->pluck('id')->flip();
        $out = [];
        foreach ($list as $i => $s) {
            $kind = $s['kind'];
            if (isset($out[$kind])) {
                throw ValidationException::withMessages(["scenarios.{$i}.kind" => 'لكل حالة سيناريو واحد.']);
            }
            $range = self::KINDS[$kind];
            $minute = $range ? (int) ($s['minute'] ?? $range[0]) : null;
            if ($range && ($minute < $range[1] || $minute > $range[2])) {
                throw ValidationException::withMessages(["scenarios.{$i}.minute" => "الدقيقة بين {$range[1]} و{$range[2]}."]);
            }
            $sub = null;
            if (! empty($s['sub'])) {
                $sub = ['out' => (int) $s['sub']['out'], 'in' => (int) $s['sub']['in']];
                if (! isset($mine[$sub['out']], $mine[$sub['in']]) || $sub['out'] === $sub['in']) {
                    throw ValidationException::withMessages(["scenarios.{$i}.sub" => 'التبديل بين لاعبين مختلفين من فريقك.']);
                }
            }
            $tactics = array_map('intval', array_intersect_key($s['tactics'] ?? [], array_flip(self::TACTICS)));
            if (! $tactics && ! $sub) {
                throw ValidationException::withMessages(["scenarios.{$i}" => 'السيناريو يحتاج تبديلاً أو تغييراً في الضغط أو الإيقاع أو الأسلوب.']);
            }
            $out[$kind] = ['kind' => $kind, 'minute' => $minute, 'tactics' => $tactics, 'sub' => $sub];
        }
        $out = array_values($out);
        $now = GameClock::now();
        if (DB::table('tactics')->where('club_id', $club->id)->update(['scenarios' => json_encode($out), 'updated_at' => $now]) === 0) {
            DB::table('tactics')->insert(['club_id' => $club->id] + Tactics::of($club) + ['scenarios' => json_encode($out), 'created_at' => $now, 'updated_at' => $now]);
        }

        return $out;
    }

    /**
     * The scenarios whose moment has come before the next minute of $state: the pure part, with the kinds
     * that already went in left out. Each comes with the orders it gives.
     *
     * @return list<array{kind: string, orders: list<array>}>
     */
    public static function due(array $state, string $side, array $scenarios, array $done): array
    {
        $other = $side === 'home' ? 'away' : 'home';
        $minute = (int) ($state['out']['minute'][0] ?? 0);
        $diff = $state['score'][$side] - $state['score'][$other];
        $due = [];
        foreach ($scenarios as $s) {
            $now = match ($s['kind']) {
                'trailing' => $diff < 0 && $minute >= $s['minute'],
                'leading' => $diff > 0 && $minute >= $s['minute'],
                'red_card' => (int) $state['teams'][$side]['stats']['red'] > 0,
                default => false,
            };
            if (! $now || in_array($s['kind'], $done, true)) {
                continue;
            }
            $orders = [];
            if ($s['tactics']) {
                $orders[] = ['type' => 'tactics', 'team' => $side, 'tactics' => $s['tactics']];
            }
            if ($s['sub']) {
                $orders[] = ['type' => 'sub', 'team' => $side, 'out' => $s['sub']['out'], 'in' => $s['sub']['in']];
            }
            $due[] = ['kind' => $s['kind'], 'orders' => $orders];
        }

        return $due;
    }
}
