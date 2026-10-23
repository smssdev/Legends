<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/** The coins wallet [docs/features/premium.md, Sprint 34]: balance, today's reward, the cap per league, the shop. */
class WalletController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();
        $cap = (int) config('game.premium.season_cap');
        $leagues = DB::table('league_memberships')->join('leagues', 'leagues.id', '=', 'league_memberships.league_id')
            ->where('league_memberships.user_id', $user->id)->whereNull('league_memberships.left_at')->where('leagues.status', '!=', 'finished')
            ->distinct()->get(['leagues.id', 'leagues.name', 'leagues.fair_league']);

        return response()->json([
            'balance' => Wallet::balance($user->id),
            'daily' => ['amount' => (int) config('game.premium.earn.daily'), 'claimed' => DB::table('wallet_transactions')->where('idempotency_key', self::dailyKey($user->id))->exists()],
            'cap' => $cap,
            'leagues' => $leagues->map(function ($l) use ($user) {
                $season = (int) DB::table('seasons')->where('league_id', $l->id)->orderByDesc('number')->value('id');

                return ['id' => $l->id, 'name' => $l->name, 'fair' => (bool) $l->fair_league, 'spent' => Wallet::spentThisSeason($user->id, $l->id, $season)];
            })->values(),
            'transactions' => DB::table('wallet_transactions')->where('user_id', $user->id)->orderByDesc('id')->limit(30)->get()
                ->map(fn ($t) => ['type' => $t->type, 'label' => Wallet::LABELS[$t->type] ?? $t->type, 'amount' => (int) $t->amount,
                    'balance_after' => (int) $t->balance_after, 'at' => Carbon::parse($t->created_at, 'UTC')->toIso8601ZuluString()]),
            'shop' => config('game.premium.shop'),
            'prices' => config('game.premium.price'),
        ]);
    }

    /** Today's reward, once a day by Cairo's calendar. */
    public function daily(Request $request): JsonResponse
    {
        Wallet::earn($request->user()->id, 'daily', self::dailyKey($request->user()->id));

        return $this->show($request);
    }

    private static function dailyKey(int $userId): string
    {
        return "daily:{$userId}:".GameClock::now()->setTimezone('Africa/Cairo')->toDateString();
    }
}
