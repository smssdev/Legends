<?php

namespace App\League;

use App\Http\Controllers\Api\DataController;
use App\Market\Pool;
use App\Models\League;
use App\Models\Season;
use App\Models\User;
use App\Season\Objectives;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Makes a whole league at once [PLAN 2.1, 2.3]: the strongest N clubs of a template copied with their
 * players into the league's own tables, each club funded with the starting budget, the first season,
 * and the owner's chosen club. Every club starts under a bot; the season starts at the owner's time.
 */
class LeagueFactory
{
    private const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';   // no 0/O or 1/I to misread

    /**
     * @param  array{name?: ?string, template: string, team_count: int, rounds_per_day: int, round_times: list<string>,
     *     prep_days: int, season_end_mode: string, starts_at: \DateTimeInterface, starting_budget: int, fair_league: bool,
     *     is_dev?: bool, master_club_id: int}  $settings
     */
    public static function create(User $owner, array $settings): League
    {
        Joining::assertCanTakeAnother($owner);
        $version = DataController::version();
        $masters = DB::table('master_clubs')->where('data_version', $version)->where('league_name', $settings['template'])
            ->orderByDesc('strength_cp')->orderBy('id')->limit($settings['team_count'])->get();
        if ($masters->count() < $settings['team_count']) {
            throw new HttpException(422, 'عدد الفرق أكبر من عدد أندية هذا الدوري.');
        }
        if (! $masters->contains('id', $settings['master_club_id'])) {
            throw new HttpException(422, 'اختر فريقك من أندية هذا الدوري.');
        }

        return DB::transaction(function () use ($owner, $settings, $version, $masters) {
            $code = self::code();
            $name = trim((string) ($settings['name'] ?? ''));
            $league = League::create([
                'owner_id' => $owner->id, 'code' => $code,
                'name' => $name !== '' ? $name : $settings['template'].' #'.$code,
                'template' => $settings['template'], 'data_version' => $version,
                'team_count' => $settings['team_count'], 'rounds_per_day' => $settings['rounds_per_day'],
                'round_times' => array_values($settings['round_times']), 'prep_days' => $settings['prep_days'],
                'starts_at' => $settings['starts_at'], 'season_end_mode' => $settings['season_end_mode'],
                'starting_budget' => $settings['starting_budget'], 'fair_league' => $settings['fair_league'], 'integrity' => $settings['integrity'] ?? false, 'second_slot_minutes' => $settings['second_slot_minutes'] ?? null,
                'is_dev' => $settings['is_dev'] ?? false, 'rest_days' => array_values($settings['rest_days'] ?? []),
                'press_conferences' => $settings['press_conferences'] ?? true, 'custom_coins' => $settings['custom_coins'] ?? 0,
            ]);
            // [UP9] A customized league is paid in coins as it is made: not enough, and nothing is made.
            if (($settings['custom_coins'] ?? 0) > 0) {
                Wallet::post($owner->id, 'league_custom', -$settings['custom_coins'], 'league_custom:'.$league->id, 'league:'.$league->id);
            }
            $rounds = self::rounds($settings['team_count']);
            $season = Season::create([
                'league_id' => $league->id, 'number' => 1, 'starts_at' => $settings['starts_at'],
                'rounds' => $rounds, 'lock_from_round' => self::lockFromRound($rounds),
            ]);

            $now = GameClock::now();
            $personalities = config('game.engine.bot_personalities');
            $chosen = null;
            foreach ($masters as $m) {
                $clubId = DB::table('clubs')->insertGetId([
                    'league_id' => $league->id, 'master_club_id' => $m->id, 'name' => $m->name, 'code' => $m->code,
                    'color_primary' => $m->color_primary, 'color_secondary' => $m->color_secondary,
                    'strength_snapshot' => $m->strength_cp,
                    'bot_personality' => $personalities[crc32($league->id.':'.$m->id) % count($personalities)],
                    'created_at' => $now, 'updated_at' => $now,
                ]);
                // One statement per club: the whole squad, with its value from the master data.
                DB::statement('insert into players (league_id, club_id, master_player_id, overall, base_value, value, created_at, updated_at)
                    select ?, ?, id, overall, value, value, ?, ? from master_players where master_club_id = ?',
                    [$league->id, $clubId, $now, $now, $m->id]);
                ClubLedger::post($clubId, 'opening', $settings['starting_budget'], "opening:{$clubId}:1", 'season:1');
                if ($m->id === $settings['master_club_id']) {
                    $chosen = $clubId;
                }
            }
            SeasonScheduler::build($league->fresh(), $season->fresh());
            Objectives::set($season->id);
            // The market pool for the preparation and the first window [Sprint 24].
            Pool::renew($league->id, DB::table('transfer_windows')->where('season_id', $season->id)->where('kind', 'summer')->value('id'));
            Joining::claim($owner, $league->fresh(), $chosen);

            return $league->fresh();
        });
    }

    /** League rounds in a season: home and away, with a rest day each round when the count is odd [PLAN 2.4]. */
    public static function rounds(int $teams): int
    {
        return $teams % 2 === 0 ? 2 * ($teams - 1) : 2 * $teams;
    }

    /** The first round of the last 25% (rounded up, so the lock is never shorter than a quarter). */
    public static function lockFromRound(int $rounds): int
    {
        $locked = intdiv($rounds * config('game.league.lock_last_bp') + 9999, 10000);

        return $rounds - $locked + 1;
    }

    private static function code(): string
    {
        $length = config('game.league.code_length');
        do {
            $code = '';
            for ($i = 0; $i < $length; $i++) {
                $code .= self::CODE_ALPHABET[random_int(0, strlen(self::CODE_ALPHABET) - 1)];
            }
        } while (DB::table('leagues')->where('code', $code)->exists());

        return $code;
    }
}
