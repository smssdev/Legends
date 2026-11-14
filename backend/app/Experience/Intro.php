<?php

namespace App\Experience;

use App\Assistant\Guide;
use App\Models\MasterClub;
use App\Simulator\Simulator;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 64 B1] A new coach's first match, before any club: a simulator match against the computer between two clubs
 * of about the same strength (neighbours among the game.experience.intro.pool strongest), with a seed from the server,
 * and three teaching moments the server decides: the minute to change the style, the minute to make a substitution,
 * and the minute the style's effect shows. Each moment carries its guide topic's words, so the screens only show them.
 */
class Intro
{
    public static function start(Simulator $sim, int $userId, string $locale): array
    {
        $c = config('game.experience.intro');
        $seed = random_int(1, 999999);
        $pool = MasterClub::query()->where('source', '!=', 'nation')->orderByDesc('strength_cp')->orderBy('id')->limit((int) $c['pool'])->pluck('id')->all();
        abort_if(count($pool) < 2, 503, 'لا توجد أندية كافية للمباراة التعريفية.');
        $i = $seed % (count($pool) - 1);
        $match = $sim->create(['home_id' => $pool[$i], 'away_id' => $pool[$i + 1], 'seed' => $seed, 'mode' => 'solo']);
        // Marked, so it plays where the simulator is off (SimulatorEnabled).
        $match->setup = $match->setup + ['intro' => true];
        $match->save();
        DB::table('users')->where('id', $userId)->whereNull('intro_started_at')->update(['intro_started_at' => GameClock::now()]);

        return $sim->view($match) + ['intro' => ['moments' => self::moments($seed, $locale)]];
    }

    /** The three moments: the minute, the kind, and its words from the guide. */
    public static function moments(int $seed, string $locale): array
    {
        $c = config('game.experience.intro');
        $at = fn (array $range, int $salt) => $range[0] + crc32("intro:{$seed}:{$salt}") % ($range[1] - $range[0] + 1);
        $style = $at($c['style_minute'], 1);
        $out = [];
        foreach (['style' => $style, 'sub' => $at($c['sub_minute'], 2), 'effect' => $style + (int) $c['effect_after']] as $kind => $minute) {
            $topic = Guide::find("intro_{$kind}", $locale);
            $out[] = ['kind' => $kind, 'minute' => $minute, 'title' => $topic['q'] ?? '', 'text' => $topic['a'] ?? ''];
        }
        usort($out, fn ($a, $b) => $a['minute'] <=> $b['minute']);

        return $out;
    }

    public static function finished(int $userId): void
    {
        DB::table('users')->where('id', $userId)->whereNull('intro_finished_at')->update(['intro_finished_at' => GameClock::now()]);
    }
}
