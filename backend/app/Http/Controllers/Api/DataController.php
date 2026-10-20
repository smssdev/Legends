<?php

namespace App\Http\Controllers\Api;

use App\Data\Crest;
use App\Http\Controllers\Controller;
use App\Models\MasterClub;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

/**
 * The real clubs and players everyone shares [PLAN 2.6]: read-only, the same for every league.
 * Leagues are made from a template (a real league and its clubs) in Sprint 13.
 */
class DataController extends Controller
{
    /** The latest data version: new leagues use it; older leagues keep theirs. */
    public static function version(): string
    {
        return (string) DB::table('master_clubs')->max('data_version');
    }

    /** The leagues a new league can copy, strongest first. */
    public function templates(): JsonResponse
    {
        $rows = DB::table('master_clubs')->where('data_version', self::version())
            ->select('league_name as name', DB::raw('count(*) as clubs'), DB::raw('max(strength_cp) as top_strength_cp'), DB::raw('avg(strength_cp) as avg_strength_cp'))
            ->groupBy('league_name')->orderByDesc('top_strength_cp')->get()
            ->map(fn ($r) => ['name' => $r->name, 'clubs' => (int) $r->clubs, 'top_strength_cp' => (int) $r->top_strength_cp, 'avg_strength_cp' => (int) round($r->avg_strength_cp)]);

        return response()->json(['data_version' => self::version(), 'templates' => $rows]);
    }

    /** The clubs of one template, strongest first. */
    public function clubs(Request $request): JsonResponse
    {
        $data = $request->validate(['league' => ['required', 'string', 'max:80']]);
        $clubs = MasterClub::where('data_version', self::version())->where('league_name', $data['league'])->orderByDesc('strength_cp')->get();
        abort_if($clubs->isEmpty(), 404, 'لا يوجد دوري بهذا الاسم.');

        return response()->json(['league' => $data['league'], 'clubs' => $clubs->map(fn ($c) => $this->club($c))]);
    }

    /** A club with its whole squad: ratings, potential, value and the six attributes. */
    public function show(MasterClub $club): JsonResponse
    {
        $players = $club->players()->orderByRaw("case line when 'gk' then 0 when 'def' then 1 when 'mid' then 2 else 3 end")->orderByDesc('overall')->get();

        return response()->json($this->club($club) + [
            'squad_value' => (int) $players->sum('value'),
            'players' => $players->map(fn ($p) => [
                'id' => $p->id, 'name' => $p->name, 'position' => $p->position, 'line' => $p->line, 'age' => $p->age,
                'nationality' => $p->nationality, 'foot' => $p->preferred_foot,
                'overall' => $p->overall, 'potential' => $p->potential, 'value' => (int) $p->value,
                'attributes' => $p->line === 'gk'
                    ? ['diving' => $p->gk_diving, 'handling' => $p->gk_handling, 'kicking' => $p->gk_kicking, 'positioning' => $p->gk_positioning, 'reflexes' => $p->gk_reflexes]
                    : ['pac' => $p->pac, 'sho' => $p->sho, 'pas' => $p->pas, 'dri' => $p->dri, 'def' => $p->def, 'phy' => $p->phy],
            ]),
        ]);
    }

    /** The club's generated badge (no real logos). The same picture for the web and the app. */
    public function crest(Request $request, MasterClub $club): Response
    {
        $svg = Crest::svg($club->name, $club->code, $club->color_primary, $club->color_secondary);
        $etag = '"'.md5($svg).'"';
        if ($request->header('If-None-Match') === $etag) {
            return response('', 304, ['ETag' => $etag]);
        }

        return response($svg, 200, ['Content-Type' => 'image/svg+xml', 'Cache-Control' => 'public, max-age=604800', 'ETag' => $etag]);
    }

    private function club(MasterClub $c): array
    {
        return [
            'id' => $c->id, 'name' => $c->name, 'code' => $c->code, 'league' => $c->league_name,
            'strength_cp' => (int) $c->strength_cp, 'colors' => [$c->color_primary, $c->color_secondary],
            'crest_url' => url("/api/v1/data/clubs/{$c->id}/crest.svg"),
        ];
    }
}
