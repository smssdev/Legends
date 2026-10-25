<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Messages\MessageText;
use App\Models\Club;
use App\Models\League;
use App\Staff\Specialists;
use App\Support\GameClock;
use App\Wallet\Price;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/** Specialists [docs/features/specialists.md, Sprint 31]: the four, each with its price and the contract working now. */
class SpecialistController extends Controller
{
    public function show(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);

        return response()->json([
            'balance' => (int) DB::table('clubs')->where('id', $club->id)->value('balance'),
            'now' => GameClock::now()->toIso8601ZuluString(),
            'days' => intdiv(Specialists::seconds($league->id), 86400) ?: 1,
            'specialists' => array_map(function ($type) use ($club, $league) {
                $c = Specialists::current($club->id, $type);
                $next = Specialists::next($club->id, $type);
                // A price for each number of stars, and what each gives [X20].
                $offers = array_map(function ($stars) use ($league, $type) {
                    $q = Price::quote($league->id, 'specialist', Specialists::cost($league->id, $type, $stars), (int) config("game.specialists.stars_cost_bp.{$stars}"));

                    return ['stars' => $stars, 'cost' => $q['amount'], 'currency' => $q['currency'], 'effect' => self::effect($type, $stars)];
                }, [1, 2, 3, 4, 5]);
                $three = $offers[2];

                return ['type' => $type, 'name' => MessageText::STAFF[$type], 'cost' => $three['cost'], 'currency' => $three['currency'], 'offers' => $offers,
                    'stars' => $c ? (int) $c->stars : 0, 'renewed' => $next !== null,
                    'ends_at' => $c ? Carbon::parse($c->ends_at, 'UTC')->toIso8601ZuluString() : null];
            }, Specialists::TYPES),
        ]);
    }

    public function hire(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $data = $request->validate(['type' => ['required', Rule::in(Specialists::TYPES)], 'stars' => ['sometimes', 'integer', 'between:1,5'], 'idempotency_key' => 'required|string|max:64']);
        Specialists::hire($club->id, $data['type'], "specialist:{$club->id}:{$data['idempotency_key']}", (int) ($data['stars'] ?? 3));

        return $this->show($request, $league);
    }

    /** What a contract of these stars gives, in Arabic, from the config [X20]. */
    private static function effect(string $type, int $stars): string
    {
        $c = fn (string $table) => (int) config("game.specialists.{$table}.{$stars}");

        return match ($type) {
            'att_coach', 'mid_coach', 'def_coach' => sprintf('تدريب لاعبي الخط أسرع بـ %d%%', intdiv($c('coach_training_bp'), 100)),
            'keeper_coach' => sprintf('تدريب الحراس أسرع بـ %d%%، والحارس +%d في المباراة', intdiv($c('coach_training_bp'), 100), $c('keeper_coach_boost')),
            'physio' => sprintf('+%d لياقة لمن يرتاح بين المباراتين', $c('physio_rest_bonus')),
            'doctor' => sprintf('كل مباراة تُنقص الإصابة %d %s', $c('doctor_countdown'), $c('doctor_countdown') > 1 ? 'مباريات' : 'مباراة'),
            'lawyer' => sprintf('يلغي %d%% من إيقافات البطاقة الحمراء', intdiv($c('lawyer_cancel_bp'), 100)),
            'mental_coach' => sprintf('يعيد %d من المعنويات بعد التعادل أو الخسارة', $c('mental_coach_boost')),
            default => '',
        };
    }

    private function club(Request $request, League $league): Club
    {
        $club = Club::where('league_id', $league->id)->where('user_id', $request->user()->id)->first();
        abort_unless($club, 403, 'ليس لديك فريق في هذا الدوري.');

        return $club;
    }
}
