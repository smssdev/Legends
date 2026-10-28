<?php

namespace App\Http\Controllers\Api;

use App\Data\ClubLogo;
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
            // [UP11] The transfer list: the world's players, the computer's clubs' and the coaches' listed ones, by line.
            'source' => ['nullable', Rule::in(['list', 'pool', 'bots'])],
            'line' => ['nullable', Rule::in(['gk', 'def', 'mid', 'att'])],
            'q' => 'nullable|string|max:40',
            'club' => 'nullable|integer',
            'max_price' => 'nullable|integer|min:0',
        ]);
        $source = $data['source'] ?? 'list';
        if ($source === 'list') {
            return response()->json($this->transferList($club, $league, $data['line'] ?? 'gk'));
        }
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
        $squads = DB::table('players')->whereIn('club_id', $clubs->keys())->groupBy('club_id')->selectRaw('club_id, count(*) as n')->pluck('n', 'club_id');
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
                ->map(fn ($c) => ['id' => $c->id, 'name' => $c->name, 'code' => $c->code, 'players' => (int) ($squads[$c->id] ?? 0)]),
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

    /**
     * [UP11] The owner's spec (5): one list per line (no search), the world's players (their own club outside the
     * league, the "parallel" transfers), the computer's clubs' (the club alone) and the coaches' listed ones (the club
     * and its coach), with the time the offers renew.
     */
    private function transferList(Club $club, League $league, string $line): array
    {
        $cfg = config('game.economy');
        $base = fn () => DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('players.league_id', $league->id)->where('master_players.line', $line)
            ->select('players.*', 'master_players.name', 'master_players.position', 'master_players.line', 'master_players.age', 'master_players.potential',
                'master_players.nationality', 'master_players.master_club_id',
                'master_players.pac', 'master_players.sho', 'master_players.pas', 'master_players.dri', 'master_players.def', 'master_players.phy',
                'master_players.gk_diving', 'master_players.gk_handling', 'master_players.gk_kicking', 'master_players.gk_positioning', 'master_players.gk_reflexes');
        $bots = DB::table('clubs')->where('league_id', $league->id)->whereNull('user_id')->get(['id', 'name', 'master_club_id'])->keyBy('id');
        $coaches = DB::table('clubs')->join('users', 'users.id', '=', 'clubs.user_id')->where('clubs.league_id', $league->id)
            ->get(['clubs.id', 'clubs.name', 'clubs.master_club_id', 'users.name as coach'])->keyBy('id');
        $listed = DB::table('transfer_listings')->whereIn('club_id', $coaches->keys())->pluck('price', 'player_id');
        // The stars first, then the strongest of the rest [UP11].
        $world = $base()->whereNull('players.club_id')->where('players.in_pool', true)->orderByDesc('players.pool_star')->orderByDesc('players.overall')->limit(40)->get();
        $fromBots = $base()->whereIn('players.club_id', $bots->keys())->orderByDesc('players.overall')->limit(30)->get();
        $fromCoaches = $base()->whereIn('players.id', $listed->keys())->where('players.club_id', '!=', $club->id)->orderByDesc('players.overall')->get();
        // Every master club named below in one query: the world players' clubs and the league's clubs (their logos) [E1.3].
        $masters = DB::table('master_clubs')->whereIn('id', $world->pluck('master_club_id')->merge($bots->pluck('master_club_id'))->merge($coaches->pluck('master_club_id'))->filter()->unique())
            ->get(['id', 'name', 'league_name'])->keyBy('id');
        $logo = fn ($id) => isset($masters[$id]) ? ClubLogo::path($masters[$id]->league_name, $masters[$id]->name) : null;
        $row = fn ($p, int $price, array $seller) => [
            'id' => $p->id, 'name' => $p->name, 'position' => $p->position, 'line' => $p->line, 'age' => (int) $p->age,
            'overall' => (int) $p->overall + (int) $p->training_bonus, 'potential' => (int) $p->potential, 'nationality' => $p->nationality,
            'value' => (int) $p->value, 'price' => $price, 'seller' => $seller, 'star' => (bool) ($p->pool_star ?? false),
            'attributes' => $p->line === 'gk'
                ? ['diving' => $p->gk_diving, 'handling' => $p->gk_handling, 'kicking' => $p->gk_kicking, 'positioning' => $p->gk_positioning, 'reflexes' => $p->gk_reflexes]
                : ['pac' => $p->pac, 'sho' => $p->sho, 'pas' => $p->pas, 'dri' => $p->dri, 'def' => $p->def, 'phy' => $p->phy],
        ];
        $players = collect()
            ->concat($fromCoaches->map(fn ($p) => $row($p, (int) $listed[$p->id], ['kind' => 'coach', 'club_id' => $p->club_id, 'club' => $coaches[$p->club_id]->name,
                'coach' => $coaches[$p->club_id]->coach, 'logo' => $logo($coaches[$p->club_id]->master_club_id)])))
            ->concat($fromBots->map(fn ($p) => $row($p, intdiv((int) $p->value * $cfg['buy_from_bot_bp'], 10000), ['kind' => 'bot', 'club_id' => $p->club_id,
                'club' => $bots[$p->club_id]->name, 'coach' => null, 'logo' => $logo($bots[$p->club_id]->master_club_id)])))
            ->concat($world->map(fn ($p) => $row($p, intdiv((int) $p->value * $cfg['buy_from_pool_bp'], 10000), ['kind' => 'world', 'club_id' => null,
                'club' => $masters[$p->master_club_id]->name ?? null, 'coach' => null,
                'logo' => $logo($p->master_club_id)])))
            ->sortBy([['star', 'desc'], ['overall', 'desc']])->values();
        $renewed = $league->pool_renewed_at ? Carbon::parse($league->pool_renewed_at, 'UTC') : null;

        return [
            'closed' => Market::closed($league->id),
            'line' => $line,
            'balance' => (int) $club->fresh()->balance,
            'renews_at' => $renewed?->copy()->addHours((int) $cfg['pool_hours'])->toIso8601ZuluString(),
            'players' => $players,
        ];
    }

    /** [UP11] The deal before it is made: the price, the registration coins, and the cash + coins way when short. */
    public function buyQuote(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $data = $request->validate(['player_id' => 'required|integer']);
        $p = DB::table('players')->where('id', $data['player_id'])->where('league_id', $league->id)->first();
        abort_unless($p, 404, 'اللاعب غير موجود في هذا الدوري.');
        $price = Market::price($p, $club->id);
        abort_if($price === null, 409, 'هذا اللاعب ليس للبيع هنا.');

        return response()->json(Market::quote($club->id, $price));
    }

    /** [UP11] The transfers made in the league, newest first: the player, the seller, the buyer and the money. */
    public function done(Request $request, League $league): JsonResponse
    {
        $this->club($request, $league);

        return response()->json(['transfers' => Market::history($league->id)]);
    }

    private function mine(Club $club, League $league): array
    {
        $cfg = config('game.economy');
        $listed = DB::table('transfer_listings')->where('club_id', $club->id)->get()->keyBy('player_id');
        // Read once for the whole squad, not per player.
        $bought = Buyer::boughtIds($club->id);
        $scale = (int) $league->timer_scale ?: 10000;
        $fair = (bool) $league->fair_league;

        return DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.club_id', $club->id)
            ->orderByDesc('players.value')->get(['players.id', 'master_players.name', 'master_players.position', 'master_players.line', 'players.overall', 'players.training_bonus', 'players.value'])
            ->map(function ($p) use ($club, $league, $cfg, $listed, $bought, $scale, $fair) {
                $cap = Buyer::cap($p, $club->id, isset($bought[$p->id]));
                $l = $listed[$p->id] ?? null;

                return ['id' => $p->id, 'name' => $p->name, 'position' => $p->position, 'line' => $p->line, 'overall' => (int) $p->overall + (int) $p->training_bonus,
                    'value' => (int) $p->value, 'floor' => Buyer::floor($p), 'cap' => $cap,
                    'quick' => ['pays' => (int) $p->value, 'fee' => Price::quote($league->id, 'quick_sale', intdiv((int) $p->value * $cfg['quick_sale_fee_bp'], 10000), fair: $fair)],
                    // About how long the outside buyer takes, at his value and at his cap.
                    'wait_hours' => ['value' => intdiv(Buyer::wait((int) $p->value, (int) $p->value, $league->id, $scale) + 1800, 3600),
                        'cap' => intdiv(Buyer::wait($cap, (int) $p->value, $league->id, $scale) + 1800, 3600)],
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
        $data = $request->validate(['player_id' => 'required|integer', 'idempotency_key' => 'required|string|max:64', 'compensate' => 'sometimes|boolean']);
        $balance = Market::buy($club->id, $data['player_id'], "buy:{$club->id}:{$data['idempotency_key']}", (bool) ($data['compensate'] ?? false));

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
