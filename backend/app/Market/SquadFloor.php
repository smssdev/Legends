<?php

namespace App\Market;

use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [X105, the owner's request 2026-11-22] A coach's squad never falls under its floor by line: at least
 * game.economy.min_lines of each (two keepers, four defenders, four midfielders, three forwards). Every way a player
 * leaves a coach's club goes through here: the instant sale, a listing (refused at once, and its buyer waits), an
 * offer or an auction or a release clause (Transfers::check) and the end of a contract. A bot club keeps its own
 * rule (bot_min_squad and min_keepers).
 */
class SquadFloor
{
    /** @return array<string,int> line => the fewest a coach's squad may keep */
    public static function mins(): array
    {
        return array_map('intval', (array) config('game.economy.min_lines'));
    }

    /** @return array<string,int> line => how many the club has */
    public static function counts(int $clubId): array
    {
        $have = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('players.club_id', $clubId)->groupBy('master_players.line')
            ->selectRaw('master_players.line as line, count(*) as n')->pluck('n', 'line');

        return array_map(fn ($line) => (int) ($have[$line] ?? 0), array_combine(array_keys(self::mins()), array_keys(self::mins())));
    }

    /**
     * The lines a coach's club cannot sell from now, each with its reason: for the screens to say it before the tap.
     *
     * @return array<string,string>
     */
    public static function held(int $clubId): array
    {
        if (DB::table('clubs')->where('id', $clubId)->value('user_id') === null) {
            return [];
        }
        $have = self::counts($clubId);
        $held = [];
        foreach (self::mins() as $l => $min) {
            if ($min > $have[$l] - 1) {
                $held[$l] = sprintf(__('لا بد أن يبقى في فريقك %d %s على الأقل.'), $min, self::name($l));
            }
        }

        return $held;
    }

    /**
     * Why these players may not leave this club (arriving ones counted, for a swap), or null. A bot's club, or a
     * line already under its floor that does not fall further, never blocks.
     *
     * @param  int[]  $leaving
     * @param  int[]  $arriving
     */
    public static function why(int $clubId, array $leaving, array $arriving = []): ?string
    {
        if (! $leaving || DB::table('clubs')->where('id', $clubId)->value('user_id') === null) {
            return null;
        }
        $line = fn (array $ids) => DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->whereIn('players.id', $ids)->pluck('master_players.line')->countBy()->all();
        $out = $line($leaving);
        $in = $arriving ? $line($arriving) : [];
        $have = self::counts($clubId);
        foreach (self::mins() as $l => $min) {
            $change = ($in[$l] ?? 0) - ($out[$l] ?? 0);
            if ($change < 0 && $min > $have[$l] + $change) {
                return sprintf(__('لا بد أن يبقى في فريقك %d %s على الأقل.'), $min, self::name($l));
            }
        }

        return null;
    }

    /** @param  int[]  $leaving  @param  int[]  $arriving */
    public static function assert(int $clubId, array $leaving, array $arriving = []): void
    {
        if ($why = self::why($clubId, $leaving, $arriving)) {
            throw new HttpException(409, $why);
        }
    }

    private static function name(string $line): string
    {
        return match ($line) {
            'gk' => __('حراس مرمى'),
            'def' => __('مدافعين'),
            'mid' => __('لاعبي وسط'),
            default => __('مهاجمين'),
        };
    }
}
