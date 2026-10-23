<?php

namespace App\League;

use App\Models\Club;
use Illuminate\Support\Facades\DB;

/**
 * A bot club between matches [ENGINE 7, PLAN 2.2, Sprint 32]: its personality's tactics, adjusted for the match from
 * what any coach could see of the opponent: his strength, the four public tactics of his last locked match and his
 * results. It never reads the opponent's hidden tactics (they are not even passed in). The lineup rotates by fitness.
 */
class Bot
{
    /**
     * The tactics for one match. Pure: the personality, both strengths, the opponent's visible facts and a seed.
     *
     * @param  array{public: ?array, form: list<string>}  $seen  what any coach sees of the opponent
     */
    public static function tactics(string $personality, int $mine, int $theirs, array $seen, int $seed): array
    {
        $cfg = config('game.bots');
        $base = $cfg['personalities'][$personality] ?? $cfg['personalities']['adaptive'];
        $t = $base;
        // Stronger attacks more, weaker sits deeper, within a swing of its own style.
        $shift = intdiv(($mine - $theirs) * (int) $cfg['style_per_100cp'], 100);
        $swing = (int) $cfg['style_swing'];
        $t['style'] = max(0, min(100, $base['style'] + max(-$swing, min($swing, $shift))));
        $public = $seen['public'] ?? null;
        if ($personality === 'adaptive') {
            $t['plan'] = self::adaptivePlan($mine - $theirs, $public, $seed);
            if ($t['plan'] === 'counter') {
                $t['style'] = min($t['style'], 40);
            }
            // Against a counter-attacking side, leave less space; against hard tackling, keep the ball moving.
            if (($public['plan'] ?? null) === 'counter') {
                $t['style'] = min($t['style'], 50);
                $t['pressing'] = 45;
            }
            if (($public['tackling'] ?? 0) >= 2) {
                $t['tempo'] = 60;
            }
            // An opponent in form (3 wins of his last 5): a little more caution.
            if (count(array_filter($seen['form'] ?? [], fn ($r) => $r === 'W')) >= 3) {
                $t['style'] = max(0, $t['style'] - 5);
            }
        } elseif ($public && $public['trap'] && in_array($t['plan'], ['long', 'counter'], true) && crc32("trap:{$seed}") % 2 === 0) {
            // Even a stubborn bot sometimes sees the trap coming.
            $t['plan'] = 'wings';
        }

        return $t;
    }

    /** The adaptive bot's plan: from the gap in strength and the opponent's offside trap and marking. */
    private static function adaptivePlan(int $gap, ?array $public, int $seed): string
    {
        if ($gap <= -300) {
            return 'counter';
        }
        $choices = ['passing', 'wings'];
        if (! ($public['trap'] ?? 0)) {
            $choices[] = $gap >= 300 ? 'shots' : 'long';
        }
        if (($public['marking'] ?? null) === 'man') {
            $choices[] = 'wings';
        }

        return $choices[crc32("adaptive:{$seed}") % count($choices)];
    }

    /** What any coach sees of the opponent before this fixture: his last locked public tactics and his form. */
    public static function seen(int $opponentId, int $beforeFixtureId): array
    {
        $last = DB::table('fixture_sheets')->join('fixtures', 'fixtures.id', '=', 'fixture_sheets.fixture_id')
            ->where('fixture_sheets.club_id', $opponentId)->where('fixtures.id', '!=', $beforeFixtureId)->where('fixtures.status', 'finished')
            ->orderByDesc('fixtures.scheduled_at')->value('fixture_sheets.tactics');
        $form = DB::table('fixtures')->where('status', 'finished')->whereNotNull('home_goals')
            ->where(fn ($q) => $q->where('home_id', $opponentId)->orWhere('away_id', $opponentId))
            ->orderByDesc('scheduled_at')->limit(5)->get()
            ->map(function ($f) use ($opponentId) {
                [$for, $against] = $f->home_id === $opponentId ? [$f->home_goals, $f->away_goals] : [$f->away_goals, $f->home_goals];

                return $for > $against ? 'W' : ($for < $against ? 'L' : 'D');
            })->all();

        return ['public' => $last ? Tactics::public(json_decode($last, true)) : null, 'form' => $form];
    }

    /** The bot's tactics for this fixture, from the database. */
    public static function tacticsFor(Club $club, object $fixture): array
    {
        $opponent = Club::findOrFail($fixture->home_id === $club->id ? $fixture->away_id : $fixture->home_id);

        return self::tactics($club->bot_personality, (int) $club->strength_snapshot, (int) $opponent->strength_snapshot,
            self::seen($opponent->id, $fixture->id), crc32("{$fixture->id}:{$club->id}"));
    }

    /** Below this fitness a bot's player rests, while the squad allows it. */
    public static function restBelow(Club $club): int
    {
        $cfg = config('game.bots.rest_below_fitness');

        return (int) ($cfg[$club->bot_personality] ?? $cfg['default']);
    }
}
