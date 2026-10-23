<?php

namespace App\Wallet;

use App\Market\Scout;
use App\Stadium\Stadium;
use App\Support\GameClock;
use App\Training\Training;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Finish now for coins [docs/features/premium.md, Sprint 34]: a training session, a scout's search, a stadium part.
 * The coins go first (not in a fair league, within the season cap), then the thing happens as if its time had come.
 */
class Finish
{
    public static function training(int $clubId, string $line): void
    {
        DB::transaction(function () use ($clubId, $line) {
            $slot = DB::table('training_slots')->where('club_id', $clubId)->where('line', $line)->first();
            if (! $slot) {
                throw new HttpException(404, 'لا لاعب في هذه الخانة.');
            }
            self::pay($clubId, 'finish_training', (int) config('game.premium.price.finish_training'), "finish:training:{$slot->id}:{$slot->sessions}");
            DB::table('training_slots')->where('id', $slot->id)->update(['next_at' => GameClock::now()]);
            Training::session($slot->id);
        });
    }

    public static function scout(int $clubId): void
    {
        DB::transaction(function () use ($clubId) {
            $r = DB::table('scout_requests')->where('club_id', $clubId)->where('status', 'searching')->first();
            if (! $r) {
                throw new HttpException(404, 'لا بحث جارٍ للكشاف.');
            }
            self::pay($clubId, 'finish_scout', (int) config('game.premium.price.finish_scout'), "finish:scout:{$r->id}");
            DB::table('scout_requests')->where('id', $r->id)->update(['finishes_at' => GameClock::now()]);
            Scout::report($r->id);
        });
    }

    public static function stadium(int $clubId): void
    {
        DB::transaction(function () use ($clubId) {
            $b = Stadium::building($clubId);
            if (! $b) {
                throw new HttpException(404, 'لا جزء يُبنى الآن.');
            }
            self::pay($clubId, 'finish_stadium', (int) config('game.premium.price.finish_stadium_per_stage') * (int) $b->stage, "finish:stadium:{$b->id}");
            DB::table('stadium_builds')->where('id', $b->id)->update(['ends_at' => GameClock::now()]);
            Stadium::finish($b->id);
        });
    }

    private static function pay(int $clubId, string $type, int $coins, string $key): void
    {
        $club = DB::table('clubs')->where('id', $clubId)->first();
        Wallet::pay((int) $club->user_id, $club->league_id, $type, $coins, $key, "club:{$clubId}");
    }
}
