<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Market\Loans;
use App\Market\Market;
use App\Market\Transfers;
use App\Models\Club;
use App\Models\League;
use App\Support\GameClock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/** The market between coaches [Sprint 25]: the transfer list, and the offers in and out. */
class TransferController extends Controller
{
    public function show(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $cfg = config('game.economy');
        $listings = DB::table('transfer_listings')->join('players', 'players.id', '=', 'transfer_listings.player_id')
            ->join('master_players', 'master_players.id', '=', 'players.master_player_id')->join('clubs', 'clubs.id', '=', 'transfer_listings.club_id')
            ->where('clubs.league_id', $league->id)->orderByDesc('players.overall')
            ->select('transfer_listings.price', 'players.id', 'players.overall', 'players.training_bonus', 'players.value', 'master_players.name',
                'master_players.position', 'master_players.line', 'master_players.age', 'clubs.id as club_id', 'clubs.name as club_name')->get();
        $offers = DB::table('transfer_offers')->where('league_id', $league->id)
            ->where(fn ($q) => $q->where('from_club_id', $club->id)->orWhere('to_club_id', $club->id))
            ->where(fn ($q) => $q->where('status', 'pending')->orWhere('updated_at', '>=', GameClock::now()->copy()->subDays(3)))
            ->orderByDesc('id')->limit(40)->get();

        return response()->json([
            'closed' => Market::closed($league->id),
            'fair' => ['min_bp' => $cfg['human_trade_min_bp'], 'max_bp' => $cfg['human_trade_max_bp']],
            'pair_cap' => intdiv((int) $league->starting_budget * $cfg['pair_net_transfer_cap_bp'], 10000),
            'listings' => $listings->map(fn ($l) => ['player' => $this->player($l), 'price' => (int) $l->price,
                'club' => ['id' => $l->club_id, 'name' => $l->club_name], 'mine' => $l->club_id === $club->id]),
            'offers' => $offers->map(fn ($o) => $this->view($o, $club->id)),
            // The coaches' clubs to make an offer to.
            'clubs' => DB::table('clubs')->where('league_id', $league->id)->whereNotNull('user_id')->where('id', '!=', $club->id)
                ->orderBy('name')->get(['id', 'name', 'code']),
        ]);
    }

    public function list(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $data = $request->validate(['player_id' => 'required|integer', 'price' => 'required|integer|min:1', 'auction_minutes' => 'nullable|integer']);
        Transfers::list($club->id, $data['player_id'], $data['price'], $data['auction_minutes'] ?? null);

        return $this->show($request, $league);
    }

    public function unlist(Request $request, League $league, int $player): JsonResponse
    {
        Transfers::unlist($this->club($request, $league)->id, $player);

        return $this->show($request, $league);
    }

    public function offer(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $data = $this->terms($request, true);
        $id = Transfers::offer($club->id, $data['to_club_id'], $data['money'] ?? 0, $data['in'], $data['out'] ?? [], "offer:{$club->id}:{$data['idempotency_key']}", null, (int) ($data['sell_on_bp'] ?? 0));

        return response()->json(['offer' => $this->view(DB::table('transfer_offers')->find($id), $club->id)], 201);
    }

    public function accept(Request $request, League $league, int $offer): JsonResponse
    {
        $club = $this->club($request, $league);
        Transfers::accept($offer, $club->id);

        return response()->json(['offer' => $this->view(DB::table('transfer_offers')->find($offer), $club->id),
            'balance' => (int) DB::table('clubs')->where('id', $club->id)->value('balance')]);
    }

    public function reject(Request $request, League $league, int $offer): JsonResponse
    {
        $club = $this->club($request, $league);
        Transfers::reject($offer, $club->id);

        return response()->json(['offer' => $this->view(DB::table('transfer_offers')->find($offer), $club->id)]);
    }

    public function cancel(Request $request, League $league, int $offer): JsonResponse
    {
        $club = $this->club($request, $league);
        Transfers::cancel($offer, $club->id);

        return response()->json(['offer' => $this->view(DB::table('transfer_offers')->find($offer), $club->id)]);
    }

    public function counter(Request $request, League $league, int $offer): JsonResponse
    {
        $club = $this->club($request, $league);
        $data = $this->terms($request, false);
        $id = Transfers::counter($offer, $club->id, $data['money'] ?? 0, $data['in'], $data['out'] ?? [], "offer:{$club->id}:{$data['idempotency_key']}");

        return response()->json(['offer' => $this->view(DB::table('transfer_offers')->find($id), $club->id)], 201);
    }

    private function terms(Request $request, bool $to): array
    {
        return $request->validate([
            'to_club_id' => $to ? 'required|integer' : 'prohibited',
            'money' => 'nullable|integer|min:0',
            'in' => 'required|array|min:1|max:5', 'in.*' => 'integer',
            'out' => 'nullable|array|max:5', 'out.*' => 'integer',
            'idempotency_key' => 'required|string|max:64',
            'sell_on_bp' => 'nullable|integer|min:0',   // [X62] the sell-on share promised to the seller
        ]);
    }

    /** An offer as either coach sees it: "in" and "out" from the offering club's side, and whose turn it is. */
    private function view(object $o, int $me): array
    {
        $rows = DB::table('offer_items')->join('players', 'players.id', '=', 'offer_items.player_id')
            ->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('offer_id', $o->id)
            ->select('offer_items.direction', 'players.id', 'players.overall', 'players.training_bonus', 'players.value', 'master_players.name',
                'master_players.position', 'master_players.line', 'master_players.age')->get();
        $clubs = DB::table('clubs')->whereIn('id', [$o->from_club_id, $o->to_club_id])->pluck('name', 'id');

        return [
            'id' => $o->id, 'status' => $o->status, 'money' => (int) $o->money, 'sell_on_bp' => (int) ($o->sell_on_bp ?? 0),
            'from' => ['id' => $o->from_club_id, 'name' => $clubs[$o->from_club_id] ?? ''],
            'to' => ['id' => $o->to_club_id, 'name' => $clubs[$o->to_club_id] ?? ''],
            'incoming' => $o->to_club_id === $me, 'counter_of' => $o->counter_of,
            'in' => $rows->where('direction', 'in')->map(fn ($p) => $this->player($p))->values(),
            'out' => $rows->where('direction', 'out')->map(fn ($p) => $this->player($p))->values(),
            'expires_at' => Carbon::parse($o->expires_at, 'UTC')->toIso8601ZuluString(),
        ];
    }

    private function player(object $p): array
    {
        return ['id' => $p->id, 'name' => $p->name, 'position' => $p->position, 'line' => $p->line, 'age' => (int) $p->age,
            'overall' => (int) $p->overall + (int) $p->training_bonus, 'value' => (int) $p->value];
    }

    /** [X61 E2] My loans this season, asked and running. */
    public function loans(Request $request, League $league): JsonResponse
    {
        $cfg = config('game.loans');

        return response()->json(['loans' => Loans::of($this->club($request, $league)), 'max_rounds' => (int) $cfg['max_rounds'], 'max_fee_bp' => (int) $cfg['max_fee_bp']]);
    }

    public function askLoan(Request $request, League $league): JsonResponse
    {
        $data = $request->validate(['player_id' => 'required|integer', 'rounds' => 'required|integer|min:1', 'fee' => 'required|integer|min:0']);
        Loans::ask($this->club($request, $league), (int) $data['player_id'], (int) $data['rounds'], (int) $data['fee']);

        return $this->loans($request, $league);
    }

    public function answerLoan(Request $request, League $league, int $loan): JsonResponse
    {
        $data = $request->validate(['accept' => 'required|boolean']);
        Loans::answer($this->club($request, $league), $loan, (bool) $data['accept']);

        return $this->loans($request, $league);
    }

    private function club(Request $request, League $league): Club
    {
        $club = Club::where('league_id', $league->id)->where('user_id', $request->user()->id)->first();
        abort_unless($club, 403, 'ليس لديك فريق في هذا الدوري.');

        return $club;
    }
}
