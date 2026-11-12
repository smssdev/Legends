<?php

namespace App\Http\Controllers\Api;

use App\Data\Crests;
use App\Http\Controllers\Controller;
use App\League\Morale;
use App\Models\Club;
use App\Models\League;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/**
 * Tickets [X25]: a league coach goes to the other clubs' coming matches and cheers one side, which lifts its
 * morale for that match. On sale until the lock; one ticket per match.
 */
class TicketController extends Controller
{
    public function index(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $season = $league->season;
        $fixtures = DB::table('fixtures')->where('season_id', $season?->id)->where('status', 'scheduled')->where('is_bye', false)
            ->whereNotNull('home_id')->whereNotNull('away_id')->where('home_id', '!=', $club->id)->where('away_id', '!=', $club->id)
            ->orderBy('scheduled_at')->orderBy('id')->limit(12)->get();
        $clubs = DB::table('clubs')->whereIn('id', $fixtures->pluck('home_id')->merge($fixtures->pluck('away_id')))->get(['id', 'name', 'code', 'master_club_id'])->keyBy('id');
        $tickets = DB::table('match_tickets')->whereIn('fixture_id', $fixtures->pluck('id'))->get();
        $card = fn ($id) => ['id' => (int) $id, 'name' => $clubs[$id]->name, 'code' => $clubs[$id]->code,
            'crest_url' => Crests::url($clubs[$id]->master_club_id)];

        return response()->json([
            'price' => Morale::ticketPrice($league->id),
            'boost' => (int) config('game.morale.ticket'),
            'balance' => (int) $club->balance,
            'fixtures' => $fixtures->map(fn ($f) => [
                'id' => $f->id, 'competition' => $f->competition, 'round' => $f->round,
                'scheduled_at' => Carbon::parse($f->scheduled_at, 'UTC')->toIso8601ZuluString(),
                'home' => $card($f->home_id), 'away' => $card($f->away_id),
                'cheering' => ['home' => $tickets->where('fixture_id', $f->id)->where('side', 'home')->count(),
                    'away' => $tickets->where('fixture_id', $f->id)->where('side', 'away')->count()],
                'mine' => $tickets->where('fixture_id', $f->id)->firstWhere('club_id', $club->id)?->side,
            ])->values(),
        ]);
    }

    public function store(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $data = $request->validate(['fixture_id' => ['required', 'integer'], 'side' => ['required', Rule::in(['home', 'away'])]]);
        $fixture = DB::table('fixtures')->where('id', $data['fixture_id'])->where('season_id', $league->season?->id)->first();
        abort_unless($fixture, 404, 'المباراة غير موجودة في هذا الدوري.');
        Morale::buyTicket($club->id, $fixture, $data['side']);

        return $this->index($request, $league);
    }

    private function club(Request $request, League $league): Club
    {
        $club = Club::where('league_id', $league->id)->where('user_id', $request->user()->id)->first();
        abort_unless($club, 403, 'ليس لديك فريق في هذا الدوري.');

        return $club;
    }
}
