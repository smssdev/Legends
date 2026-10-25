<?php

namespace App\Http\Controllers\Api;

use App\Economy\Economy;
use App\Http\Controllers\Controller;
use App\League\Integrity;
use App\Models\Club;
use App\Models\League;
use App\Wallet\Price;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * The integrity system [X28], for a league that has it: my next match's bribe, the spies on me (when I see them)
 * and turning one, my spies' proofs and taking one to the FA, and the market ban if I am under one.
 */
class IntegrityController extends Controller
{
    public function show(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        $f = DB::table('fixtures')->where('status', 'scheduled')->where('is_bye', false)->whereNotNull('home_id')->whereNotNull('away_id')
            ->where(fn ($q) => $q->where('home_id', $club->id)->orWhere('away_id', $club->id))->orderBy('scheduled_at')->first();
        $sees = $f && Integrity::seesSpies($club->id, $f->id);
        $money = Integrity::bribeMoney($league->id);

        return response()->json([
            'on' => (bool) $league->integrity,
            'fixture' => $f ? ['id' => $f->id, 'opponent' => DB::table('clubs')->where('id', $f->home_id === $club->id ? $f->away_id : $f->home_id)->value('name')] : null,
            'bribe' => ['paid' => $f && DB::table('bribes')->where('fixture_id', $f->id)->where('club_id', $club->id)->exists(),
                'money' => $money, 'extra' => Price::quote($league->id, 'bribe', $money), 'var_percent' => intdiv((int) config('game.integrity.var_bp'), 100)],
            'security' => ['sees' => $sees, 'cost' => Price::quote($league->id, 'security_check', $this->cost($league, 'security_check'))],
            'double_agent' => Price::quote($league->id, 'double_agent', $this->cost($league, 'double_agent')),
            'spies_on_me' => $sees ? Integrity::spiesOn($club->id, $f->id) : [],
            // My spies' reports that found a bribe, and whether I took them to the FA.
            'proofs' => DB::table('spy_reports')->join('clubs', 'clubs.id', '=', 'spy_reports.target_club_id')->where('spy_reports.club_id', $club->id)
                ->orderByDesc('spy_reports.id')->limit(10)->get(['spy_reports.id', 'spy_reports.report', 'spy_reports.fixture_id', 'spy_reports.target_club_id', 'clubs.name'])
                ->filter(fn ($s) => json_decode($s->report, true)['bribed'] ?? false)
                ->map(fn ($s) => ['spy_report_id' => $s->id, 'club' => $s->name,
                    'filed' => DB::table('fa_cases')->join('bribes', 'bribes.id', '=', 'fa_cases.bribe_id')->where('bribes.fixture_id', $s->fixture_id)->where('bribes.club_id', $s->target_club_id)->exists()])
                ->values(),
            'banned_until' => $club->market_banned_until ? Carbon::parse($club->market_banned_until, 'UTC')->toIso8601ZuluString() : null,
            'headlines' => Integrity::headlines($league->id),
        ]);
    }

    public function bribe(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        Integrity::bribe($club->id, (int) $request->validate(['fixture_id' => ['required', 'integer']])['fixture_id']);

        return $this->show($request, $league);
    }

    public function security(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request, $league);
        Integrity::securityCheck($club->id, (int) $request->validate(['fixture_id' => ['required', 'integer']])['fixture_id']);

        return $this->show($request, $league);
    }

    public function turn(Request $request, League $league, int $spy): JsonResponse
    {
        Integrity::turn($this->club($request, $league)->id, $spy);

        return $this->show($request, $league);
    }

    public function accuse(Request $request, League $league, int $spy): JsonResponse
    {
        $verdict = Integrity::accuse($this->club($request, $league)->id, $spy);

        return response()->json(['verdict' => $verdict] + $this->show($request, $league)->getData(true));
    }

    private function cost(League $league, string $feature): int
    {
        return intdiv(Economy::scale($league->id) * (int) config("game.integrity.{$feature}_cost_bp"), 10000);
    }

    private function club(Request $request, League $league): Club
    {
        $club = Club::where('league_id', $league->id)->where('user_id', $request->user()->id)->first();
        abort_unless($club, 403, 'ليس لديك فريق في هذا الدوري.');

        return $club;
    }
}
