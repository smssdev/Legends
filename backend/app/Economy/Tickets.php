<?php

namespace App\Economy;

use App\Models\League;
use App\Stadium\Stadium;
use Illuminate\Support\Facades\DB;

/**
 * [X61] The ticket price a club sets, one of four levels (game.economy.ticket_levels): what each level would bring
 * at the next home match, for the stadium and finance screens, and the coach's choice. The gate itself is posted after
 * each home match (Economy::afterMatch).
 */
class Tickets
{
    public const NAMES = ['popular' => 'شعبي', 'normal' => 'عادي', 'high' => 'مرتفع', 'premium' => 'مميز'];

    public static function level(int $clubId): string
    {
        $level = (string) DB::table('clubs')->where('id', $clubId)->value('ticket_level');

        return isset(self::NAMES[$level]) ? $level : 'normal';
    }

    public static function set(int $clubId, string $level): void
    {
        DB::table('clubs')->where('id', $clubId)->update(['ticket_level' => $level]);
    }

    /** Each level with its seat price, crowd and gate at the next home match, and the one chosen. */
    public static function view(League $league, object $club): array
    {
        $money = Money::fromConfig();
        [$min, $max] = Economy::strengthRange($league->id);
        $scale = Economy::scale($league->id);
        $rounds = (int) $league->season->rounds;
        $attendance = $money->attendance((int) $club->strength_snapshot, $min, $max);
        $capacity = Stadium::capacity($club->id);
        $chosen = self::level($club->id);

        return [
            'level' => $chosen,
            'per_match' => $money->tickets($scale, $rounds, $attendance, $capacity, $chosen),
            'levels' => array_map(function ($level) use ($money, $scale, $rounds, $attendance, $capacity) {
                [$att, $priceBp] = $money->priced($attendance, $level);

                return ['level' => $level, 'name' => __(self::NAMES[$level]), 'price' => intdiv($money->ticketPrice($scale, $rounds) * $priceBp, 10000),
                    'attendance_bp' => $att, 'per_match' => $money->tickets($scale, $rounds, $attendance, $capacity, $level)];
            }, array_keys(self::NAMES)),
        ];
    }
}
