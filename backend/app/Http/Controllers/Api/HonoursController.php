<?php

namespace App\Http\Controllers\Api;

use App\Auth\Username;
use App\Data\Crests;
use App\Http\Controllers\Controller;
use App\League\Awards;
use App\Models\League;
use App\Models\User;
use App\Season\Career;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * The record that stays across seasons [PLAN 2.11, Sprint 33]: a league's hall of fame (every season's champions,
 * podium and cup), and a coach's profile (titles, objectives met, and his record as a coach).
 */
class HonoursController extends Controller
{
    /** [X61 E5] The running season's awards, for the league's members. */
    public function awards(Request $request, League $league): JsonResponse
    {
        $member = DB::table('league_memberships')->where('league_id', $league->id)->where('user_id', $request->user()->id)->exists()
            || $league->owner_id === $request->user()->id;
        abort_unless($member, 403, 'الأوسمة لأعضاء الدوري.');
        abort_unless($league->season, 404, 'لا موسم في هذا الدوري بعد.');

        return response()->json(Awards::of($league->id, $league->season->id));
    }

    public function league(Request $request, League $league): JsonResponse
    {
        $member = DB::table('league_memberships')->where('league_id', $league->id)->where('user_id', $request->user()->id)->exists()
            || $league->owner_id === $request->user()->id;
        abort_unless($member, 403, 'قاعة الشرف لأعضاء الدوري.');
        $titles = DB::table('titles')->join('clubs', 'clubs.id', '=', 'titles.club_id')->leftJoin('users', 'users.id', '=', 'titles.user_id')
            ->join('seasons', 'seasons.id', '=', 'titles.season_id')->where('titles.league_id', $league->id)
            ->orderByDesc('seasons.number')->orderBy('titles.competition', 'desc')->orderBy('titles.position')
            ->get(['seasons.number', 'titles.competition', 'titles.position', 'clubs.id as club_id', 'clubs.name as club', 'clubs.master_club_id', 'users.id as user_id', 'users.name as coach']);
        $seasons = DB::table('seasons')->where('league_id', $league->id)->orderByDesc('number')->get(['id', 'number', 'status', 'finished_at']);

        return response()->json([
            'league' => ['id' => $league->id, 'name' => $league->name],
            'seasons' => $seasons->map(fn ($s) => [
                'number' => (int) $s->number, 'status' => $s->status,
                'titles' => $titles->where('number', $s->number)->values()->map(fn ($t) => [
                    'competition' => $t->competition, 'position' => (int) $t->position,
                    'club' => ['id' => $t->club_id, 'name' => $t->club, 'crest_url' => Crests::url($t->master_club_id)],
                    'coach' => $t->user_id ? ['id' => $t->user_id, 'name' => $t->coach] : null,
                ])->all(),
            ])->all(),
        ]);
    }

    public function coach(Request $request, User $user): JsonResponse
    {
        $titles = DB::table('titles')->join('leagues', 'leagues.id', '=', 'titles.league_id')->join('seasons', 'seasons.id', '=', 'titles.season_id')
            ->join('clubs', 'clubs.id', '=', 'titles.club_id')->where('titles.user_id', $user->id)
            ->orderByDesc('titles.id')->get(['leagues.name as league', 'seasons.number', 'titles.competition', 'titles.position', 'clubs.name as club']);
        $objectives = DB::table('club_objectives')->join('clubs', 'clubs.id', '=', 'club_objectives.club_id')
            ->join('seasons', 'seasons.id', '=', 'club_objectives.season_id')->join('leagues', 'leagues.id', '=', 'seasons.league_id')
            ->where('club_objectives.user_id', $user->id)->whereNotNull('club_objectives.achieved')
            ->orderByDesc('club_objectives.id')->get(['leagues.name as league', 'seasons.number', 'clubs.name as club', 'club_objectives.competition',
                'club_objectives.target', 'club_objectives.kind', 'club_objectives.result', 'club_objectives.achieved']);

        return response()->json([
            'coach' => ['id' => $user->id, 'account_no' => $user->account_no, 'name' => $user->name, 'official' => Username::official($user->username), 'verified' => $user->account_verified_at !== null],
            'record' => Career::record($user->id),
            'titles' => $titles->map(fn ($t) => ['league' => $t->league, 'season' => (int) $t->number, 'competition' => $t->competition,
                'position' => (int) $t->position, 'club' => $t->club])->all(),
            'objectives' => [
                'met' => $objectives->where('achieved', 1)->count(), 'total' => $objectives->count(),
                'list' => $objectives->map(fn ($o) => ['league' => $o->league, 'season' => (int) $o->number, 'club' => $o->club,
                    'competition' => $o->competition, 'target' => $o->target, 'kind' => $o->kind, 'result' => $o->result, 'achieved' => (bool) $o->achieved])->all(),
            ],
        ]);
    }
}
