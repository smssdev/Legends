<?php

namespace App\Training;

use App\Economy\Economy;
use App\League\ClubLedger;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Secret training [docs/features/secret-training.md, Sprint 28]: before the club's next match and until the lock,
 * one line trains in secret and plays that match only with +3 on the rating and every attribute. Five a season.
 * It reaches the match through its first state (LeagueMatch), so the replay keeps it; the opponent never sees it.
 */
class SecretTraining
{
    public const LINES = ['gk', 'def', 'mid', 'att'];

    public static function cost(int $leagueId): int
    {
        return intdiv(Economy::scale($leagueId) * (int) config('game.secret_training.cost_bp'), 10000);
    }

    public static function usedThisSeason(int $clubId, int $seasonId): int
    {
        return DB::table('secret_trainings')->where('club_id', $clubId)->where('season_id', $seasonId)->count();
    }

    /** The extra points for a line of this club in this fixture: [line => points], or empty. */
    public static function boosts(int $clubId, int $fixtureId): array
    {
        $line = DB::table('secret_trainings')->where('club_id', $clubId)->where('fixture_id', $fixtureId)->value('line');

        return $line ? [$line => (int) config('game.secret_training.boost')] : [];
    }

    /** The club's next match, the one a secret session would be for. */
    public static function nextFixture(int $clubId): ?object
    {
        return DB::table('fixtures')->whereIn('status', ['scheduled', 'locked', 'live'])->where('is_bye', false)
            ->where(fn ($q) => $q->where('home_id', $clubId)->orWhere('away_id', $clubId))
            ->whereNotNull('home_id')->whereNotNull('away_id')->orderBy('scheduled_at')->first();
    }

    public static function order(int $clubId, object $fixture, string $line): void
    {
        DB::transaction(function () use ($clubId, $fixture, $line) {
            if ($fixture->status !== 'scheduled') {
                throw new HttpException(409, 'قُفلت التشكيلة، فلا تدريب سري لهذه المباراة.');
            }
            $club = DB::table('clubs')->where('id', $clubId)->first();
            if (DB::table('secret_trainings')->where('club_id', $clubId)->where('fixture_id', $fixture->id)->exists()) {
                throw new HttpException(409, 'طلبت تدريباً سرياً لهذه المباراة.');
            }
            $max = (int) config('game.secret_training.per_season');
            if (self::usedThisSeason($clubId, $fixture->season_id) >= $max) {
                throw new HttpException(409, "استخدمت التدريب السري {$max} مرات هذا الموسم.");
            }
            $cost = self::cost($club->league_id);
            $now = GameClock::now();
            $id = DB::table('secret_trainings')->insertGetId(['club_id' => $clubId, 'fixture_id' => $fixture->id, 'season_id' => $fixture->season_id,
                'line' => $line, 'cost' => $cost, 'created_at' => $now, 'updated_at' => $now]);
            ClubLedger::post($clubId, 'secret_training', -$cost, "secret:{$id}", "fixture:{$fixture->id}", spend: true);
        });
    }
}
