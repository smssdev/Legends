<?php

namespace App\Tournament;

use App\Data\ClubLogo;
use App\Http\Controllers\Api\DataController;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 29] What a tournament is made from: the templates (World Cup, Club World Cup, AFCON, EURO, Asian Cup,
 * custom) with the teams each suggests, the national teams, and the countries the data cannot field yet (too few
 * players or no goalkeeper; the data editor completes them).
 */
class TournamentCatalog
{
    public static function card(object $m): array
    {
        return ['id' => (int) $m->id, 'name' => $m->name, 'code' => $m->code, 'league' => $m->league_name, 'strength_cp' => (int) $m->strength_cp,
            'colors' => [$m->color_primary, $m->color_secondary], 'crest_url' => url("/api/v1/data/clubs/{$m->id}/crest.svg"),
            'logo' => ClubLogo::path($m->league_name, $m->name), 'nation' => $m->source === NationSquad::SOURCE, 'confederation' => $m->confederation];
    }

    public static function nations(): array
    {
        return DB::table('master_clubs')->where('data_version', DataController::version())->where('source', NationSquad::SOURCE)
            ->orderByDesc('strength_cp')->orderBy('id')->get()->map(fn ($m) => self::card($m))->all();
    }

    /** The countries in the data without a team yet: their players and goalkeepers. */
    public static function missing(): array
    {
        $version = DataController::version();

        return Cache::remember("tournaments:missing:{$version}", 600, function () use ($version) {
            $out = [];
            foreach (NationSquad::players($version) as $name => $players) {
                if (! NationSquad::playable($players)) {
                    $out[] = ['name' => $name, 'players' => count($players), 'keepers' => count(array_filter($players, fn ($p) => $p->line === 'gk'))];
                }
            }
            usort($out, fn ($a, $b) => $b['players'] <=> $a['players']);

            return $out;
        });
    }

    /** The template's suggested teams (master club ids) and its shape fitted to them. */
    public static function suggest(string $key): array
    {
        $t = config("game.tournaments.templates.{$key}");
        $version = DataController::version();
        $q = DB::table('master_clubs')->where('data_version', $version)->orderByDesc('strength_cp')->orderBy('id');
        $ids = [];
        if ($t['pool'] === 'nations') {
            $ids = $q->where('source', NationSquad::SOURCE)->when($t['confederation'] ?? null, fn ($w, $c) => $w->where('confederation', $c))
                ->limit($t['teams'])->pluck('id')->all();
        } elseif ($t['pool'] === 'clubs') {
            $per = [];
            foreach ($q->where('source', '!=', NationSquad::SOURCE)->limit(400)->get(['id', 'league_name']) as $c) {
                if (($per[$c->league_name] = ($per[$c->league_name] ?? 0) + 1) <= $t['per_league']) {
                    $ids[] = $c->id;
                }
                if (count($ids) >= $t['teams']) {
                    break;
                }
            }
        }
        $n = count($ids);
        // Fewer teams than the template's: fewer groups, at least three teams in each.
        $groups = $t['groups'];
        while ($groups > 1 && intdiv($n, $groups) < 3) {
            $groups = intdiv($groups, 2);
        }

        return ['key' => $key, 'pool' => $t['pool'], 'confederation' => $t['confederation'] ?? null, 'format' => $t['format'],
            'group_count' => $groups, 'advance_per_group' => 2, 'legs' => 1, 'teams' => array_map('intval', $ids)];
    }
}
