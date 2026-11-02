<?php

namespace App\Http\Controllers\Api;

use App\Data\KitPattern;
use App\Http\Controllers\Controller;
use App\Rules\NotJunk;
use App\Support\GameClock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/**
 * [X62 E8] The game's data editor in the admin panel, by the owner's decision (2026-10-30): the clubs and players of
 * the latest data version, searched, corrected, added and (when no league uses them) removed. Each change is kept in
 * data_edits. A league already running keeps its own copy of ratings and values (players); names, ages and the
 * attributes are read from here, so a correction shows everywhere at once.
 */
class DataEditorController extends Controller
{
    private const PLAYER = ['name', 'position', 'line', 'age', 'nationality', 'overall', 'potential', 'value', 'master_club_id'];

    private const CLUB = ['name', 'code', 'league_name', 'color_primary', 'color_secondary', 'kit_pattern', 'away_color', 'away_pattern'];

    private static function version(): string
    {
        return (string) DB::table('master_clubs')->max('data_version');
    }

    /** Search: players or clubs whose name has the words. */
    public function search(Request $request): JsonResponse
    {
        $data = $request->validate(['kind' => ['required', Rule::in(['players', 'clubs'])], 'q' => 'nullable|string|max:60', 'club_id' => 'nullable|integer']);
        $q = trim((string) ($data['q'] ?? ''));
        if ($data['kind'] === 'clubs') {
            $rows = DB::table('master_clubs')->where('data_version', self::version())->when($q !== '', fn ($w) => $w->whereLike('name', "%{$q}%"))
                ->orderBy('league_name')->orderBy('name')->limit(40)->get(['id', ...self::CLUB, 'strength_cp']);
        } else {
            $rows = DB::table('master_players')->join('master_clubs', 'master_clubs.id', '=', 'master_players.master_club_id')
                ->where('master_players.data_version', self::version())->when($q !== '', fn ($w) => $w->whereLike('master_players.name', "%{$q}%"))
                ->when($data['club_id'] ?? null, fn ($w, $c) => $w->where('master_players.master_club_id', $c))
                ->orderByDesc('master_players.overall')->limit(40)
                ->get(['master_players.id', ...array_map(fn ($c) => "master_players.{$c}", self::PLAYER), 'master_clubs.name as club']);
        }

        return response()->json(['rows' => $rows]);
    }

    /** The data's leagues, with their clubs, and those too small for a new league (under six). */
    public function leagues(): JsonResponse
    {
        $rows = DB::table('master_clubs')->where('data_version', self::version())->groupBy('league_name')
            ->selectRaw('league_name as name, count(*) as clubs')->orderBy('league_name')->get()
            ->map(fn ($r) => ['name' => $r->name, 'clubs' => (int) $r->clubs, 'too_small' => (int) $r->clubs < 6]);

        return response()->json(['leagues' => $rows]);
    }

    public function updatePlayer(Request $request, int $id): JsonResponse
    {
        $row = DB::table('master_players')->where('id', $id)->first();
        abort_unless($row, 404);
        $data = $request->validate($this->playerRules(false));

        return response()->json(['row' => $this->change('player', 'master_players', $request, $row, $data)]);
    }

    public function updateClub(Request $request, int $id): JsonResponse
    {
        $row = DB::table('master_clubs')->where('id', $id)->first();
        abort_unless($row, 404);
        $data = $request->validate($this->clubRules(false, $id));

        return response()->json(['row' => $this->change('club', 'master_clubs', $request, $row, $data)]);
    }

    /** A new player in a club: his attributes start at his rating (the keepers' for a keeper). */
    public function createPlayer(Request $request): JsonResponse
    {
        $data = $request->validate($this->playerRules(true));
        $now = GameClock::now();
        $attrs = $data['line'] === 'gk'
            ? array_fill_keys(['gk_diving', 'gk_handling', 'gk_kicking', 'gk_positioning', 'gk_reflexes'], $data['overall'])
            : array_fill_keys(['pac', 'sho', 'pas', 'dri', 'def', 'phy'], $data['overall']);
        $id = DB::table('master_players')->insertGetId($data + $attrs + ['data_version' => self::version(), 'source' => 'editor',
            'external_id' => 900_000_000 + (int) DB::table('master_players')->max('id') + 1, 'created_at' => $now, 'updated_at' => $now]);
        $this->log($request, 'player', $id, 'create', $data);

        return response()->json(['row' => DB::table('master_players')->find($id)], 201);
    }

    public function createClub(Request $request): JsonResponse
    {
        $data = $request->validate($this->clubRules(true, null));
        $now = GameClock::now();
        $id = DB::table('master_clubs')->insertGetId($data + ['data_version' => self::version(), 'source' => 'editor', 'strength_cp' => 6000,
            'created_at' => $now, 'updated_at' => $now]);
        $this->log($request, 'club', $id, 'create', $data);

        return response()->json(['row' => DB::table('master_clubs')->find($id)], 201);
    }

    /** Only what no league has taken, and [Sprint 30 P2] only with the player's name typed to confirm. */
    public function deletePlayer(Request $request, int $id): JsonResponse
    {
        $row = DB::table('master_players')->where('id', $id)->first();
        abort_unless($row, 404);
        abort_unless(trim((string) $request->query('confirm')) === trim((string) $row->name), 422, 'اكتب اسم اللاعب كما هو لتأكيد الحذف.');
        abort_if(DB::table('players')->where('master_player_id', $id)->exists(), 409, 'لاعب في دوري قائم: صحّح بياناته بدل حذفه.');
        DB::table('master_players')->where('id', $id)->delete();
        $this->log($request, 'player', $id, 'delete', (array) $row);

        return response()->json(['deleted' => true]);
    }

    private function change(string $kind, string $table, Request $request, object $row, array $data): object
    {
        $before = array_intersect_key((array) $row, $data);
        $changed = array_filter($data, fn ($v, $k) => (string) ($before[$k] ?? '') !== (string) $v, ARRAY_FILTER_USE_BOTH);
        if ($changed) {
            DB::table($table)->where('id', $row->id)->update($changed + ['updated_at' => GameClock::now()]);
            $this->log($request, $kind, (int) $row->id, 'update', ['before' => array_intersect_key($before, $changed), 'after' => $changed]);
        }

        return DB::table($table)->find($row->id);
    }

    private function log(Request $request, string $kind, int $id, string $action, array $changes): void
    {
        DB::table('data_edits')->insert(['user_id' => $request->user()->id, 'kind' => $kind, 'target_id' => $id, 'action' => $action,
            'changes' => json_encode($changes, JSON_UNESCAPED_UNICODE), 'created_at' => GameClock::now()]);
    }

    private function playerRules(bool $create): array
    {
        $r = $create ? 'required' : 'sometimes';

        return [
            'name' => [$r, 'string', 'min:2', 'max:80', new NotJunk], 'position' => [$r, 'string', 'max:4'], 'line' => [$r, Rule::in(['gk', 'def', 'mid', 'att'])],
            'age' => [$r, 'integer', 'between:15,45'], 'nationality' => ['sometimes', 'nullable', 'string', 'max:60'],
            'overall' => [$r, 'integer', 'between:30,99'], 'potential' => [$r, 'integer', 'between:30,99', 'gte:overall'],
            'value' => [$r, 'integer', 'min:1000'], 'master_club_id' => [$r, 'integer', Rule::exists('master_clubs', 'id')],
        ];
    }

    private function clubRules(bool $create, ?int $id): array
    {
        $r = $create ? 'required' : 'sometimes';
        $unique = Rule::unique('master_clubs', 'name')->where('data_version', self::version())->ignore($id);

        return [
            'name' => [$r, 'string', 'min:2', 'max:60', $unique, new NotJunk], 'code' => [$r, 'string', 'between:2,4'], 'league_name' => [$r, 'string', 'min:2', 'max:80', new NotJunk],
            'color_primary' => [$r, 'regex:/^#[0-9A-Fa-f]{6}$/'], 'color_secondary' => [$r, 'regex:/^#[0-9A-Fa-f]{6}$/'],
            // [X76] The kit's pattern in the club's two colours.
            'kit_pattern' => ['sometimes', 'nullable', Rule::in(KitPattern::ALL)],
            // [Sprint 34 V1] The change kit: its shirt colour (empty: none) and pattern.
            'away_color' => ['sometimes', 'nullable', 'regex:/^#[0-9A-Fa-f]{6}$/'], 'away_pattern' => ['sometimes', 'nullable', Rule::in(KitPattern::ALL)],
        ];
    }
}
