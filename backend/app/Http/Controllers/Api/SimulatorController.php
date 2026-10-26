<?php

namespace App\Http\Controllers\Api;

use App\Engine\Formations;
use App\Http\Controllers\Controller;
use App\Models\MasterClub;
use App\Models\SimMatch;
use App\Models\SimRoom;
use App\Simulator\Simulator;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/** Simulator API (docs/MATCH_VIEW.md 8, docs/api/openapi.yaml). */
class SimulatorController extends Controller
{
    public function __construct(private Simulator $sim) {}

    public function leagues()
    {
        return DB::table('master_clubs')->select('league_name as name', DB::raw('count(*) as clubs'), DB::raw('max(strength_cp) as top'))
            ->groupBy('league_name')->orderByDesc('top')->get();
    }

    public function clubs(Request $request)
    {
        $data = $request->validate(['q' => 'nullable|string|max:60', 'league' => 'nullable|string|max:80']);

        return MasterClub::query()
            ->when($data['q'] ?? null, fn ($q, $term) => $q->whereLike('name', '%'.$term.'%'))
            ->when($data['league'] ?? null, fn ($q, $league) => $q->where('league_name', $league))
            ->orderByDesc('strength_cp')->limit(60)
            ->get(['id', 'name', 'code', 'league_name', 'strength_cp', 'color_primary', 'color_secondary']);
    }

    public function club(MasterClub $club)
    {
        return $this->sim->squad($club);
    }

    public function store(Request $request)
    {
        $tactics = ['nullable', 'array'];
        $data = $request->validate([
            'home_id' => 'required|integer|exists:master_clubs,id',
            'away_id' => 'required|integer|exists:master_clubs,id|different:home_id',
            'seed' => 'nullable|integer|min:1|max:999999999',
            'competition' => 'nullable|in:league,cup',
            'referee' => 'nullable|integer|between:0,2',
            'venue' => 'nullable|in:home,neutral',
            'mode' => 'nullable|in:solo,live',
            'control.home' => 'nullable|in:me,cpu',
            'control.away' => 'nullable|in:me,cpu',
            'home.formation' => ['nullable', Rule::in(Formations::names())],
            'away.formation' => ['nullable', Rule::in(Formations::names())],
            'home.tactics' => $tactics,
            'away.tactics' => $tactics,
        ]);

        $match = $this->sim->create($data);
        $view = $this->sim->view($match, $match->seats ? 'home' : null);

        // A live match made here: the maker holds home and sends the away seat to the friend.
        return response()->json($view + ($match->seats ? ['seats' => $match->seats] : []), 201);
    }

    public function show(Request $request, SimMatch $match)
    {
        return $this->sim->view($match, $this->you($request, $match));
    }

    /** The side the request's seat (X-Seat) manages in a live match. */
    private function you(Request $request, SimMatch $match): ?string
    {
        return Simulator::seatSide($match, $request->header('X-Seat'));
    }

    public function order(Request $request, SimMatch $match)
    {
        $data = $request->validate([
            'type' => 'required|in:sub,tactics,formation',
            'team' => 'required|in:home,away',
            'out' => 'required_if:type,sub|integer',
            'in' => 'required_if:type,sub|integer',
            'tactics' => 'required_if:type,tactics|array',
            'formation' => ['required_if:type,formation', 'nullable', Rule::in(Formations::names())],
            'idempotency_key' => 'required|string|max:64',
        ]);
        abort_if($match->state['finished'], 409, 'انتهت المباراة.');
        // A live match: each coach orders only his own side, from the device that holds its seat.
        abort_if($match->live !== null && $this->you($request, $match) !== $data['team'], 403, 'لا تستطيع إدارة فريق صديقك.');

        $order = array_filter([
            'type' => $data['type'], 'team' => $data['team'], 'out' => $data['out'] ?? null, 'in' => $data['in'] ?? null,
            'tactics' => $data['tactics'] ?? null, 'formation' => $data['formation'] ?? null,
        ], fn ($v) => $v !== null) + ['key' => $data['idempotency_key']];
        $result = $this->sim->order($match, $order);

        return response()->json($result, $result['duplicate'] ? 200 : 202);
    }

    public function ticks(Request $request, SimMatch $match)
    {
        $data = $request->validate(['count' => 'nullable|integer|min:1|max:200']);
        abort_if($match->live !== null, 409, 'المباراة المباشرة يديرها الخادم.');

        return ['ticks' => $this->sim->advance($match, (int) ($data['count'] ?? 1))];
    }

    public function start(Request $request, SimMatch $match)
    {
        abort_if($match->live === null, 409, 'هذه ليست مباراة مباشرة.');
        abort_if($this->you($request, $match) === null, 403, 'يبدأ المباراة أحد المدربين.');
        $this->sim->start($match);

        return $this->sim->sync($match, $match->state['tick'], $this->you($request, $match));
    }

    public function live(Request $request, SimMatch $match)
    {
        abort_if($match->live === null, 409, 'هذه ليست مباراة مباشرة.');
        $since = (int) ($request->validate(['since' => 'nullable|integer|min:0'])['since'] ?? 0);

        return $this->sim->sync($match, $since, $this->you($request, $match));
    }

    public function react(Request $request, SimMatch $match)
    {
        $data = $request->validate(['key' => ['required', Rule::in(config('game.match.reactions'))]]);
        abort_if($match->live === null, 409, 'هذه ليست مباراة مباشرة.');
        $side = $this->you($request, $match);
        abort_if($side === null, 403, 'التفاعل للمدربين فقط.');

        return response()->json($this->sim->react($match, $side, $data['key']), 201);
    }

    public function report(Request $request, SimMatch $match)
    {
        $side = $request->validate(['side' => 'nullable|in:home,away'])['side'] ?? 'home';
        abort_unless($match->state['finished'], 409, 'المباراة لم تنته بعد.');

        return $this->sim->report($match, $side);
    }

    // ---------------------------------------------------------------- rooms: a match between two friends

    public function roomStore(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|min:2|max:24',
            'club_id' => 'required|integer|exists:master_clubs,id',
        ]);
        $room = SimRoom::create(['host_name' => trim($data['name']), 'host_club_id' => $data['club_id'], 'host_seat' => Simulator::newSeat()]);

        // The seat is given once, to the host's device; it becomes the home seat of the match.
        return response()->json($this->room($room) + ['seat' => $room->host_seat], 201);
    }

    public function roomShow(SimRoom $room)
    {
        return $this->room($room);
    }

    public function roomJoin(Request $request, SimRoom $room)
    {
        $data = $request->validate([
            'name' => 'required|string|min:2|max:24',
            'club_id' => ['required', 'integer', 'exists:master_clubs,id', Rule::notIn([$room->host_club_id])],
        ], ['club_id.not_in' => 'اختر نادياً غير نادي صديقك.']);
        $seat = $this->sim->join($room, trim($data['name']), (int) $data['club_id']);

        return $this->room($room->refresh()) + ['seat' => $seat];
    }

    private function room(SimRoom $room): array
    {
        $club = fn ($c) => $c ? $c->only(['id', 'name', 'code', 'color_primary', 'color_secondary', 'strength_cp']) : null;

        return [
            'id' => $room->id,
            'host' => ['name' => $room->host_name, 'club' => $club($room->hostClub)],
            'guest' => $room->guest_name ? ['name' => $room->guest_name, 'club' => $club($room->guestClub)] : null,
            'match_id' => $room->sim_match_id,
        ];
    }
}
