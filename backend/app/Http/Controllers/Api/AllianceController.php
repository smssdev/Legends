<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\League\Alliance;
use App\League\Members;
use App\Models\League;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * The alliance tournament [X27]: the league's latest one with its alliances and its rounds, the owner's
 * request (it goes to the developers), and a captain's pick between two of his coaches. The developers
 * approve or turn it down from the admin panel (AdminController).
 */
class AllianceController extends Controller
{
    public function show(Request $request, League $league): JsonResponse
    {
        $user = $request->user();
        abort_unless($league->isOwner($user) || Members::isMember($user->id, $league->id), 404);

        return response()->json(self::view($league, $user));
    }

    public function store(Request $request, League $league): JsonResponse
    {
        abort_unless($league->isOwner($request->user()), 403, 'هذا لمنشئ الدوري فقط.');
        [$min, $max] = config('game.alliance.sizes');
        $data = $request->validate([
            'name' => ['required', 'string', 'min:3', 'max:40'],
            'captain_a' => ['required', 'string', 'max:20'],
            'captain_b' => ['required', 'string', 'max:20'],
            'size' => ['required', 'integer', "between:{$min},{$max}"],
            'first_round_at' => ['required', 'date'],
        ]);
        Alliance::create($league, $request->user(), $data);

        return response()->json(self::view($league, $request->user()), 201);
    }

    public function decide(Request $request, League $league, int $tie): JsonResponse
    {
        $data = $request->validate(['winner' => ['required', 'integer']]);
        abort_unless(DB::table('alliance_ties')->join('alliance_tournaments', 'alliance_tournaments.id', '=', 'alliance_ties.tournament_id')
            ->where('alliance_ties.id', $tie)->where('alliance_tournaments.league_id', $league->id)->exists(), 404);
        Alliance::decide($tie, $request->user(), (int) $data['winner']);

        return response()->json(self::view($league, $request->user()));
    }

    /** [Sprint 40 D2] The one who went on: up to swap_max players, one for one, with the team he passed. */
    public function swap(Request $request, League $league, int $tie): JsonResponse
    {
        $data = $request->validate(['give' => ['required', 'array', 'min:1'], 'give.*' => ['integer'], 'take' => ['required', 'array', 'min:1'], 'take.*' => ['integer']]);
        abort_unless(DB::table('alliance_ties')->join('alliance_tournaments', 'alliance_tournaments.id', '=', 'alliance_ties.tournament_id')
            ->where('alliance_ties.id', $tie)->where('alliance_tournaments.league_id', $league->id)->exists(), 404);
        Alliance::swap($tie, $request->user(), $data['give'], $data['take']);

        return response()->json(self::view($league, $request->user()));
    }

    /** The latest tournament as everyone in the league sees it (the admin panel uses it too). */
    public static function view(League $league, ?User $user): array
    {
        $t = DB::table('alliance_tournaments')->where('league_id', $league->id)->orderByDesc('id')->first();
        $coaches = DB::table('clubs')->join('users', 'users.id', '=', 'clubs.user_id')->where('clubs.league_id', $league->id)
            ->orderBy('users.username')->get(['users.username', 'users.name']);
        $base = [
            'can_create' => $user && $league->isOwner($user) && (! $t || in_array($t->status, ['rejected', 'finished'], true)),
            'sizes' => config('game.alliance.sizes'), 'default_size' => (int) config('game.alliance.default_size'),
            'coaches' => $coaches->map(fn ($c) => ['username' => $c->username, 'name' => $c->name])->values(),
        ];
        if (! $t) {
            return $base + ['tournament' => null];
        }
        $clubs = DB::table('clubs')->leftJoin('users', 'users.id', '=', 'clubs.user_id')->where('clubs.league_id', $league->id)
            ->get(['clubs.id', 'clubs.name', 'clubs.code', 'clubs.master_club_id', 'users.name as coach'])->keyBy('id');
        $card = fn ($id) => $id && isset($clubs[$id]) ? ['id' => (int) $id, 'name' => $clubs[$id]->name, 'code' => $clubs[$id]->code, 'coach' => $clubs[$id]->coach,
            'crest_url' => url("/api/v1/data/clubs/{$clubs[$id]->master_club_id}/crest.svg")] : null;
        $members = DB::table('alliance_members')->where('tournament_id', $t->id)->get();
        $captains = DB::table('users')->whereIn('id', [$t->captain_a, $t->captain_b])->pluck('name', 'id');
        $fixtures = DB::table('fixtures')->whereIn('id', DB::table('alliance_ties')->where('tournament_id', $t->id)->whereNotNull('fixture_id')->pluck('fixture_id'))
            ->get(['id', 'status', 'home_goals', 'away_goals'])->keyBy('id');
        $matchIds = DB::table('matches')->whereIn('fixture_id', $fixtures->keys())->pluck('id', 'fixture_id');
        $myAlliance = $user && ! $t->assign ? ((int) $t->captain_a === $user->id ? 'a' : ((int) $t->captain_b === $user->id ? 'b' : null)) : null;
        // [Sprint 40 D2] This user's club, for his pick in a tie of team-mates and his swap.
        $myClub = $user ? (int) DB::table('clubs')->where('league_id', $league->id)->where('user_id', $user->id)->value('id') : 0;
        $plan = json_decode((string) ($t->plan ?? ''), true);

        return $base + ['tournament' => [
            'id' => $t->id, 'name' => $t->name, 'status' => $t->status, 'size' => (int) $t->size, 'winner' => $t->winner,
            'first_round_at' => Carbon::parse($t->first_round_at, 'UTC')->toIso8601ZuluString(), 'review_note' => $t->review_note,
            'captain_of' => $myAlliance,
            // [Sprint 40 D1] Planned as the league was made: the draw or the maker's split, and whether formed yet.
            'assign' => $t->assign, 'formed' => $t->formed_at !== null || $t->assign === null, 'plan' => $plan ?: null,
            'my_club_id' => $myClub ?: null, 'swap_max' => (int) config('game.alliance.swap_max'),
            'alliances' => collect(['a', 'b'])->mapWithKeys(fn ($a) => [$a => [
                'captain' => $captains[$a === 'a' ? $t->captain_a : $t->captain_b] ?? null,
                'clubs' => $members->where('alliance', $a)->map(fn ($m) => $card($m->club_id))->values(),
            ]]),
            'ties' => DB::table('alliance_ties')->where('tournament_id', $t->id)->orderBy('round')->orderBy('id')->get()->map(fn ($x) => [
                'id' => $x->id, 'round' => $x->round, 'kind' => $x->kind, 'home' => $card($x->home_id), 'away' => $card($x->away_id),
                'alliance' => $members->firstWhere('club_id', $x->home_id)?->alliance,
                'scheduled_at' => Carbon::parse($x->scheduled_at, 'UTC')->toIso8601ZuluString(), 'winner_id' => $x->winner_id ? (int) $x->winner_id : null,
                'status' => $x->fixture_id ? $fixtures[$x->fixture_id]->status ?? null : null,
                'score' => $x->fixture_id && isset($fixtures[$x->fixture_id]) && $fixtures[$x->fixture_id]->home_goals !== null
                    ? ['home' => (int) $fixtures[$x->fixture_id]->home_goals, 'away' => (int) $fixtures[$x->fixture_id]->away_goals] : null,
                'match_id' => $x->fixture_id ? ($matchIds[$x->fixture_id] ?? null) : null,
                // [Sprint 40 D2] Each coach's pick of who goes on, and the swaps made.
                'home_pick' => $x->home_pick ? (int) $x->home_pick : null, 'away_pick' => $x->away_pick ? (int) $x->away_pick : null,
                'swaps' => (int) ($x->swaps ?? 0),
            ])->values(),
        ]];
    }
}
