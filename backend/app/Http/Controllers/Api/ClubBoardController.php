<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\League\ClubAgenda;
use App\League\Integrity;
use App\League\MissedMatches;
use App\League\Spy;
use App\League\Standings;
use App\League\Tactics;
use App\League\TeamSheet;
use App\Models\Club;
use App\Models\League;
use App\Wallet\Wallet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * The club board [Sprint 20 B1, B3; W2 to W5, W7]: everything the board and the top bar show, in one request, and the
 * matches the coach missed. Every number comes from here; the opponent's private tactics never do.
 */
class ClubBoardController extends Controller
{
    public function summary(Request $request, League $league): JsonResponse
    {
        $user = $request->user();
        $club = $this->club($request, $league);
        $season = (int) DB::table('seasons')->where('league_id', $league->id)->orderByDesc('number')->value('id');
        $f = ClubAgenda::nextFixture($club);
        $sheet = TeamSheet::current($club);
        $pending = ClubAgenda::pending($club, $league, $user->id);
        [$table, $played] = $season ? $this->table($season) : [[], 0];
        $position = ($i = array_search($club->id, array_column($table, 'id'), true)) === false ? null : $i + 1;
        $card = fn (Club $c) => ['id' => $c->id, 'name' => $c->name, 'code' => $c->code, 'strength_cp' => (int) $c->strength_snapshot,
            'crest_url' => url("/api/v1/data/clubs/{$c->master_club_id}/crest.svg"), 'form' => Spy::form($c->id)];
        $match = null;
        if ($f) {
            $opp = Club::with('user')->find($f->home_id === $club->id ? $f->away_id : $f->home_id);
            $theirs = $f->status !== 'scheduled' ? DB::table('fixture_sheets')->where('fixture_id', $f->id)->where('club_id', $opp->id)->first() : null;
            $match = ['fixture_id' => $f->id, 'match_id' => DB::table('matches')->where('fixture_id', $f->id)->value('id'), 'competition' => $f->competition, 'round' => (int) $f->round,
                'venue' => $f->home_id === $club->id ? 'home' : 'away', 'status' => $f->status, 'scheduled_at' => Carbon::parse($f->scheduled_at, 'UTC')->toIso8601ZuluString(),
                'referee' => $f->referee_strictness, 'club' => $card($club),
                // His formation and public tactics only after the lock, as everywhere.
                'opponent' => $card($opp) + ['coach' => $opp->user?->name, 'formation' => $theirs?->formation, 'tactics' => $theirs ? Tactics::public(json_decode($theirs->tactics, true)) : null]];
        }
        $mini = array_slice($table, 0, 3);
        if ($position && $position > 3) {
            $mini[] = $table[$position - 1];
        }

        return response()->json([
            'club' => ['id' => $club->id, 'name' => $club->name, 'code' => $club->code, 'crest_url' => url("/api/v1/data/clubs/{$club->master_club_id}/crest.svg")],
            'money' => ['cash' => (int) $club->fresh()->balance, 'coins' => Wallet::balance($user->id)],
            'match' => $match,
            'lineup' => ['formation' => $sheet['formation'], 'auto' => (bool) $sheet['auto'], 'ready' => ! collect($pending)->contains('kind', 'lineup')],
            'standings' => ['position' => $position, 'teams' => count($table), 'played' => $played,
                'top' => array_map(fn ($r) => $r + ['position' => array_search($r['id'], array_column($table, 'id'), true) + 1, 'mine' => $r['id'] === $club->id], $mini)],
            'board' => $season ? ClubAgenda::board($club, $season, $position, $played) : null,
            'timers' => ClubAgenda::timers($club, $league, $user->id),
            'pending' => $pending,
            'missed' => count(MissedMatches::of($club, $user->id)),
        ]);
    }

    public function missed(Request $request, League $league): JsonResponse
    {
        return response()->json(['matches' => MissedMatches::of($this->club($request, $league), $request->user()->id)]);
    }

    /** "Skip": the listed matches (all of them when none is named) are seen. */
    public function seen(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $ids = $request->validate(['match_ids' => ['sometimes', 'array', 'max:20'], 'match_ids.*' => ['integer']])['match_ids'] ?? null;
        $mine = array_column(MissedMatches::of($club, $request->user()->id), 'match_id');
        MissedMatches::seen($request->user()->id, $ids === null ? $mine : array_values(array_intersect($mine, array_map('intval', $ids))));

        return response()->json(['matches' => MissedMatches::of($club, $request->user()->id)]);
    }

    /** The league table in the order the standings use: each club's id, name, code and points; and rounds played. */
    private function table(int $seasonId): array
    {
        $order = Standings::order($seasonId);
        $done = DB::table('fixtures')->where('season_id', $seasonId)->where('competition', 'league')->where('is_bye', false)->where('status', 'finished')->get(['home_id', 'away_id', 'home_goals', 'away_goals', 'round']);
        $off = Integrity::deductions($seasonId);
        $pts = [];
        foreach ($done as $f) {
            $pts[$f->home_id] = ($pts[$f->home_id] ?? 0) + ($f->home_goals > $f->away_goals ? 3 : ($f->home_goals === $f->away_goals ? 1 : 0));
            $pts[$f->away_id] = ($pts[$f->away_id] ?? 0) + ($f->away_goals > $f->home_goals ? 3 : ($f->home_goals === $f->away_goals ? 1 : 0));
        }
        $clubs = DB::table('clubs')->whereIn('id', $order)->get(['id', 'name', 'code'])->keyBy('id');

        return [array_map(fn ($id) => ['id' => (int) $id, 'name' => $clubs[$id]->name ?? '', 'code' => $clubs[$id]->code ?? '', 'points' => ($pts[$id] ?? 0) - ($off[$id] ?? 0)], $order),
            (int) $done->max('round')];
    }

    private function club(Request $request, League $league): Club
    {
        $club = Club::where('league_id', $league->id)->where('user_id', $request->user()->id)->first();
        abort_unless($club, 403, 'ليس لديك فريق في هذا الدوري.');

        return $club;
    }
}
