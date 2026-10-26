<?php

namespace App\League;

use App\Economy\Economy;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * The coaches' predictions [UP12, the owner's spec 6]: any coach of the league picks the winner (or a draw) of each
 * match of the round until it is locked. Once it is played, a right pick pays the predictor's club in that league
 * game.press.prediction_cash_bp of its money scale, and counts on his career (Career, xp_prediction).
 */
class Predictions
{
    public const PICKS = ['home', 'draw', 'away'];

    /** The round's matches still to be picked or being played, with this coach's picks and everyone's split. */
    public static function round(int $leagueId, int $userId): array
    {
        $season = DB::table('seasons')->where('league_id', $leagueId)->orderByDesc('number')->first();
        if (! $season) {
            return ['round' => null, 'matches' => []];
        }
        $next = DB::table('fixtures')->where('season_id', $season->id)->where('competition', 'league')->where('is_bye', false)
            ->whereIn('status', ['scheduled', 'locked', 'live'])->orderBy('scheduled_at')->first();
        if (! $next) {
            return ['round' => null, 'matches' => []];
        }
        $fixtures = DB::table('fixtures')->where('season_id', $season->id)->where('competition', 'league')->where('round', $next->round)->where('is_bye', false)->orderBy('id')->get();
        $clubs = DB::table('clubs')->where('league_id', $leagueId)->get(['id', 'name', 'code'])->keyBy('id');
        $picks = DB::table('match_predictions')->whereIn('fixture_id', $fixtures->pluck('id'))->get()->groupBy('fixture_id');

        return ['round' => (int) $next->round, 'reward' => self::reward($leagueId), 'matches' => $fixtures->map(fn ($f) => [
            'fixture_id' => $f->id, 'status' => $f->status, 'open' => $f->status === 'scheduled',
            'home' => ['id' => $f->home_id, 'name' => $clubs[$f->home_id]->name ?? '', 'code' => $clubs[$f->home_id]->code ?? ''],
            'away' => ['id' => $f->away_id, 'name' => $clubs[$f->away_id]->name ?? '', 'code' => $clubs[$f->away_id]->code ?? ''],
            'mine' => optional(($picks[$f->id] ?? collect())->firstWhere('user_id', $userId))->pick,
            'split' => array_map(fn ($p) => ($picks[$f->id] ?? collect())->where('pick', $p)->count(), array_combine(self::PICKS, self::PICKS)),
        ])->values()->all()];
    }

    public static function pick(int $leagueId, int $userId, int $fixtureId, string $pick): void
    {
        abort_unless(in_array($pick, self::PICKS, true), 422, 'اختر فوز صاحب الأرض أو التعادل أو فوز الضيف.');
        $f = DB::table('fixtures')->join('seasons', 'seasons.id', '=', 'fixtures.season_id')->where('fixtures.id', $fixtureId)
            ->where('seasons.league_id', $leagueId)->select('fixtures.*')->first();
        abort_unless($f && ! $f->is_bye, 404, 'المباراة غير موجودة في هذا الدوري.');
        if ($f->status !== 'scheduled') {
            throw new HttpException(409, 'أُغلق التوقع: قُفلت تشكيلة المباراة.');
        }
        $now = GameClock::now();
        DB::table('match_predictions')->upsert([['league_id' => $leagueId, 'fixture_id' => $fixtureId, 'user_id' => $userId, 'pick' => $pick, 'created_at' => $now, 'updated_at' => $now]],
            ['fixture_id', 'user_id'], ['pick', 'updated_at']);
    }

    /** After the match: each pick right or wrong, and the right ones paid, once (the key). */
    public static function settle(object $fixture, int $homeGoals, int $awayGoals): void
    {
        $result = $homeGoals > $awayGoals ? 'home' : ($homeGoals < $awayGoals ? 'away' : 'draw');
        $leagueId = (int) DB::table('seasons')->where('id', $fixture->season_id)->value('league_id');
        $reward = self::reward($leagueId);
        foreach (DB::table('match_predictions')->where('fixture_id', $fixture->id)->whereNull('correct')->get() as $p) {
            $right = $p->pick === $result;
            DB::table('match_predictions')->where('id', $p->id)->update(['correct' => $right, 'updated_at' => GameClock::now()]);
            $club = DB::table('clubs')->where('league_id', $leagueId)->where('user_id', $p->user_id)->value('id');
            if ($right && $club && $reward > 0) {
                ClubLedger::post((int) $club, 'prediction', $reward, "prediction:{$p->id}", "fixture:{$fixture->id}");
            }
        }
    }

    public static function reward(int $leagueId): int
    {
        return intdiv(Economy::scale($leagueId) * (int) config('game.press.prediction_cash_bp'), 10000);
    }
}
