<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Market\Buyer;
use App\Market\Market;
use App\Models\Club;
use App\Models\League;
use App\Wallet\Price;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/**
 * The market [Sprint 24]: the pool and the bot clubs, buying and selling. For a coach with a club in the
 * league. Prices come from the server (100% of value from the pool, 125% from a bot; selling at once at the full
 * value for a fee, or listing up to the sale cap for a buyer from outside [X6]).
 */
class MarketController extends Controller
{
    public function show(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $data = $request->validate([
            'source' => ['nullable', Rule::in(['pool', 'bots'])],
            'line' => ['nullable', Rule::in(['gk', 'def', 'mid', 'att'])],
            'q' => 'nullable|string|max:40',
            'club' => 'nullable|integer',
            'max_price' => 'nullable|integer|min:0',
        ]);
        $source = $data['source'] ?? 'pool';
        $cfg = config('game.economy');
        $q = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('players.league_id', $league->id)
            ->select('players.*', 'master_players.name', 'master_players.position', 'master_players.line', 'master_players.age', 'master_players.potential', 'master_players.nationality',
                'master_players.pac', 'master_players.sho', 'master_players.pas', 'master_players.dri', 'master_players.def', 'master_players.phy',
                'master_players.gk_diving', 'master_players.gk_handling', 'master_players.gk_kicking', 'master_players.gk_positioning', 'master_players.gk_reflexes')
            ->when($data['line'] ?? null, fn ($q, $line) => $q->where('master_players.line', $line))
            ->when($data['q'] ?? null, fn ($q, $name) => $q->whereLike('master_players.name', '%'.str_replace(['%', '_'], '', $name).'%'));
        if ($source === 'pool') {
            $q->whereNull('players.club_id')->where('players.in_pool', true);
            $bp = $cfg['buy_from_pool_bp'];
        } else {
            $bots = DB::table('clubs')->where('league_id', $league->id)->whereNull('user_id')->pluck('id');
            $q->whereIn('players.club_id', isset($data['club']) ? $bots->intersect([$data['club']]) : $bots);
            $bp = $cfg['buy_from_bot_bp'];
        }
        if (isset($data['max_price'])) {
            $q->whereRaw('players.value * ? / 10000 <= ?', [$bp, $data['max_price']]);
        }
        $clubs = DB::table('clubs')->where('league_id', $league->id)->pluck('name', 'id');
        $rows = $q->orderByDesc('players.overall')->orderBy('players.id')->limit(80)->get();

        return response()->json([
            'closed' => Market::closed($league->id),
            'open_until_round' => (int) $league->season->lock_from_round - 1,
            'counts' => [
                'pool' => DB::table('players')->where('league_id', $league->id)->whereNull('club_id')->where('in_pool', true)->count(),
                'bots' => DB::table('players')->whereIn('club_id', DB::table('clubs')->where('league_id', $league->id)->whereNull('user_id')->select('id'))->count(),
            ],
            'balance' => (int) $club->fresh()->balance,
            'bots' => DB::table('clubs')->where('league_id', $league->id)->whereNull('user_id')->orderBy('name')->get(['id', 'name', 'code'])
                ->map(fn ($c) => ['id' => $c->id, 'name' => $c->name, 'code' => $c->code, 'players' => DB::table('players')->where('club_id', $c->id)->count()]),
            'players' => $rows->map(fn ($p) => [
                'id' => $p->id, 'name' => $p->name, 'position' => $p->position, 'line' => $p->line, 'age' => (int) $p->age,
                'overall' => (int) $p->overall + (int) $p->training_bonus, 'potential' => (int) $p->potential, 'nationality' => $p->nationality,
                'value' => (int) $p->value, 'price' => intdiv((int) $p->value * $bp, 10000),
                'club' => $p->club_id ? ['id' => $p->club_id, 'name' => $clubs[$p->club_id] ?? ''] : null,
                // For the player's card in the market [X29].
                'attributes' => $p->line === 'gk'
                    ? ['diving' => $p->gk_diving, 'handling' => $p->gk_handling, 'kicking' => $p->gk_kicking, 'positioning' => $p->gk_positioning, 'reflexes' => $p->gk_reflexes]
                    : ['pac' => $p->pac, 'sho' => $p->sho, 'pas' => $p->pas, 'dri' => $p->dri, 'def' => $p->def, 'phy' => $p->phy],
            ]),
            // My players and the ways to sell each [X6]: now for a fee at his full value, or listed up to his cap.
            'mine' => $this->mine($club, $league),
        ]);
    }

    private function mine(Club $club, League $league): array
    {
        $cfg = config('game.economy');
        $listed = DB::table('transfer_listings')->where('club_id', $club->id)->get()->keyBy('player_id');

        return DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.club_id', $club->id)
            ->orderByDesc('players.value')->get(['players.id', 'master_players.name', 'master_players.position', 'master_players.line', 'players.overall', 'players.training_bonus', 'players.value'])
            ->map(function ($p) use ($club, $league, $cfg, $listed) {
                $cap = Buyer::cap($p, $club->id);
                $l = $listed[$p->id] ?? null;

                return ['id' => $p->id, 'name' => $p->name, 'position' => $p->position, 'line' => $p->line, 'overall' => (int) $p->overall + (int) $p->training_bonus,
                    'value' => (int) $p->value, 'floor' => Buyer::floor($p), 'cap' => $cap,
                    'quick' => ['pays' => (int) $p->value, 'fee' => Price::quote($league->id, 'quick_sale', intdiv((int) $p->value * $cfg['quick_sale_fee_bp'], 10000))],
                    // About how long the outside buyer takes, at his value and at his cap.
                    'wait_hours' => ['value' => intdiv(Buyer::wait((int) $p->value, (int) $p->value, $league->id) + 1800, 3600),
                        'cap' => intdiv(Buyer::wait($cap, (int) $p->value, $league->id) + 1800, 3600)],
                    'listed' => $l ? ['price' => (int) $l->price, 'sells_at' => $l->sells_at ? Carbon::parse($l->sells_at, 'UTC')->toIso8601ZuluString() : null] : null,
                ];
            })->all();
    }

    /** How long the outside buyer takes at a price [X6]: for the price field as the coach types. */
    public function quote(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $data = $request->validate(['player_id' => 'required|integer', 'price' => 'required|integer|min:1']);
        $p = DB::table('players')->where('id', $data['player_id'])->where('club_id', $club->id)->first();
        abort_unless($p, 404, 'اللاعب ليس في فريقك.');
        [$floor, $cap] = [Buyer::floor($p), Buyer::cap($p, $club->id)];

        return response()->json(['floor' => $floor, 'cap' => $cap, 'ok' => $data['price'] >= $floor && $data['price'] <= $cap,
            'wait_hours' => intdiv(Buyer::wait(min($cap, max($floor, $data['price'])), (int) $p->value, $league->id) + 1800, 3600)]);
    }

    public function buy(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $data = $request->validate(['player_id' => 'required|integer', 'idempotency_key' => 'required|string|max:64']);
        $balance = Market::buy($club->id, $data['player_id'], "buy:{$club->id}:{$data['idempotency_key']}");

        return response()->json(['balance' => $balance]);
    }

    public function sell(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $data = $request->validate(['player_id' => 'required|integer', 'idempotency_key' => 'required|string|max:64']);
        $balance = Market::sell($club->id, $data['player_id'], "sell:{$club->id}:{$data['idempotency_key']}");

        return response()->json(['balance' => $balance]);
    }

    private function club(Request $request, League $league): Club
    {
        $club = Club::where('league_id', $league->id)->where('user_id', $request->user()->id)->first();
        abort_unless($club, 403, 'ليس لديك فريق في هذا الدوري.');

        return $club;
    }
}
