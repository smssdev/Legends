<?php

namespace App\Market;

use App\Economy\Contracts;
use App\League\ClubLedger;
use App\League\ClubStrength;
use App\League\Integrity;
use App\Support\GameClock;
use App\Support\Nation;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [X61 E3] The youth academy: every `days` days it brings each club `offers` prospects of `max_age` or under, drawn
 * from the data (read only) among the players not yet in the league, the same for that club all the period. Their
 * potential is hidden, a range of `range` either side until one is signed. A prospect costs `price_bp` of his value,
 * and a club signs `per_season` of them at most in a season. Like every player, he goes back to the data at the
 * season's end.
 */
class Academy
{
    public static function period(): int
    {
        return intdiv(GameClock::now()->getTimestamp(), 86400 * max(1, (int) config('game.academy.days')));
    }

    /** This period's prospects for a club. */
    public static function prospects(object $club): array
    {
        $cfg = config('game.academy');
        $version = DB::table('master_players')->max('data_version');
        $ids = DB::table('master_players')->where('data_version', $version)->where('age', '<=', $cfg['max_age'])
            ->whereNotIn('id', DB::table('players')->where('league_id', $club->league_id)->select('master_player_id'))
            ->orderBy('id')->pluck('id')->all();
        if (! $ids) {
            return [];
        }
        // The same draw all the period for this club, different for each club and period.
        mt_srand(crc32("academy:{$club->id}:".self::period()));
        $picked = [];
        for ($i = 0; $i < 50 && count($picked) < (int) $cfg['offers']; $i++) {
            $picked[$ids[mt_rand(0, count($ids) - 1)]] = true;
        }
        mt_srand();
        $range = (int) $cfg['range'];

        return DB::table('master_players')->whereIn('id', array_keys($picked))->orderByDesc('potential')->get()
            ->map(fn ($p) => ['id' => (int) $p->id, 'name' => $p->name, 'position' => $p->position, 'line' => $p->line, 'age' => (int) $p->age,
                'nationality' => Nation::name($p->nationality), 'overall' => (int) $p->overall,
                'potential_from' => max((int) $p->overall, (int) $p->potential - $range), 'potential_to' => min(99, (int) $p->potential + $range),
                'price' => self::price((int) $p->value)])->all();
    }

    public static function price(int $value): int
    {
        return max(1, intdiv($value * (int) config('game.academy.price_bp'), 10000));
    }

    public static function signedThisSeason(int $clubId, ?int $seasonId): int
    {
        return (int) DB::table('players')->where('club_id', $clubId)->where('academy_season_id', $seasonId)->count();
    }

    /** Sign one of this period's prospects: he joins the club at his data's rating, his true potential shown. */
    public static function sign(object $club, int $masterId, ?int $seasonId): int
    {
        Integrity::assertMarket($club->id);
        if (! in_array($masterId, array_column(self::prospects($club), 'id'), true)) {
            throw new HttpException(404, 'هذا الشاب ليس من مواهب أكاديميتك الآن.');
        }

        return DB::transaction(function () use ($club, $masterId, $seasonId) {
            if (self::signedThisSeason($club->id, $seasonId) >= (int) config('game.academy.per_season')) {
                throw new HttpException(409, sprintf(__('وقّعت مع %d مواهب من الأكاديمية هذا الموسم، وهذا الحد.'), (int) config('game.academy.per_season')));
            }
            $m = DB::table('master_players')->where('id', $masterId)->first();
            Contracts::assertRoom($club->id, (int) $m->value);
            $now = GameClock::now();
            $inserted = DB::table('players')->insertOrIgnore(['league_id' => $club->league_id, 'club_id' => $club->id, 'master_player_id' => $masterId,
                'overall' => $m->overall, 'base_value' => $m->value, 'value' => $m->value, 'bought_for' => self::price((int) $m->value),
                'academy_season_id' => $seasonId, 'created_at' => $now, 'updated_at' => $now]);
            if ($inserted !== 1) {
                throw new HttpException(409, 'سبقك نادٍ آخر إلى هذا الشاب.');
            }
            $id = (int) DB::table('players')->where('league_id', $club->league_id)->where('master_player_id', $masterId)->value('id');
            ClubStrength::refresh((int) $club->id);   // [X98]
            ClubLedger::post($club->id, 'academy', -self::price((int) $m->value), "academy:{$club->id}:{$masterId}", "player:{$id}", spend: true);

            return $id;
        });
    }
}
