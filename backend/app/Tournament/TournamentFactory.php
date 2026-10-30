<?php

namespace App\Tournament;

use App\Http\Controllers\Api\DataController;
use App\League\ClubLedger;
use App\League\Joining;
use App\League\LeagueFactory;
use App\League\LeagueTiers;
use App\League\LiveDraw;
use App\League\SeasonScheduler;
use App\Models\League;
use App\Models\Season;
use App\Models\User;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [Sprint 27] Makes a tournament: a league of kind "tournament" with the teams its maker chose (clubs and national
 * teams together, 2 to 32), its shape (a league, groups then a knockout, or a knockout) and its draw. Each club comes
 * with its own players; each national team takes the best of its nationality who are not already in one of the clubs.
 * Every team starts under a bot; coaches join by its code and take a team as in a league. One season, then it ends.
 */
class TournamentFactory
{
    /**
     * @param  array{name?: ?string, template: string, teams: list<int>, format: string, group_count?: ?int, advance_per_group?: ?int,
     *     legs?: ?int, rounds_per_day: int, round_times: list<string>, prep_days: int, starts_at: \DateTimeInterface, starting_budget: int,
     *     draw_at?: ?string, club_id?: ?int, is_dev?: bool}  $s
     */
    public static function create(User $owner, array $s): League
    {
        $version = DataController::version();
        $ids = array_values(array_unique(array_map('intval', $s['teams'])));
        $masters = DB::table('master_clubs')->where('data_version', $version)->whereIn('id', $ids)->get()->keyBy('id');
        if ($masters->count() !== count($ids)) {
            throw new HttpException(422, 'بعض الفرق المختارة غير موجودة.');
        }
        self::assertShape(count($ids), $s);
        if (isset($s['club_id']) && ! in_array((int) $s['club_id'], $ids, true)) {
            throw new HttpException(422, 'اختر فريقك من فرق البطولة.');
        }
        if (isset($s['club_id'])) {
            Joining::assertCanTakeAnother($owner);
        }

        return DB::transaction(function () use ($owner, $s, $version, $masters) {
            $code = LeagueFactory::code();
            $name = trim((string) ($s['name'] ?? ''));
            $league = League::create([
                'owner_id' => $owner->id, 'code' => $code, 'name' => $name !== '' ? $name : __('بطولة').' #'.$code,
                'template' => 'Tournament', 'data_version' => $version, 'team_count' => $masters->count(),
                'rounds_per_day' => $s['rounds_per_day'], 'round_times' => array_values($s['round_times']), 'prep_days' => $s['prep_days'],
                'starts_at' => $s['starts_at'], 'season_end_mode' => 'end', 'starting_budget' => $s['starting_budget'],
                'fair_league' => false, 'is_dev' => $s['is_dev'] ?? false, 'press_conferences' => true, 'custom_coins' => self::cost($masters->count(), $s),
                'kind' => 'tournament', 'format' => $s['format'], 'tournament_template' => $s['template'],
                'group_count' => $s['format'] === 'groups' ? (int) $s['group_count'] : null,
                'advance_per_group' => $s['format'] === 'groups' ? (int) ($s['advance_per_group'] ?? 2) : null,
                'legs' => $s['format'] === 'knockout' ? null : (int) ($s['legs'] ?? 1),
            ]);
            // [X65] Paid in coins as it is made, as a customized league (the owner's decision 2026-10-30): not enough, nothing is made.
            if ($league->custom_coins > 0) {
                Wallet::post($owner->id, 'league_custom', -$league->custom_coins, 'tournament:'.$league->id, 'league:'.$league->id);
            }
            // Joining stays open to the end: a tournament is short and the bots fill every seat anyway.
            $season = Season::create(['league_id' => $league->id, 'number' => 1, 'starts_at' => $s['starts_at'], 'rounds' => 0, 'lock_from_round' => 255]);

            $now = GameClock::now();
            $personalities = config('game.engine.bot_personalities');
            $taken = [];
            $made = [];
            // The clubs first, with their own players; then the national teams from who is left.
            foreach ($masters->sortBy(fn ($m) => $m->source === NationSquad::SOURCE ? 1 : 0) as $m) {
                $clubId = DB::table('clubs')->insertGetId([
                    'league_id' => $league->id, 'master_club_id' => $m->id, 'name' => $m->name, 'code' => $m->code,
                    'color_primary' => $m->color_primary, 'color_secondary' => $m->color_secondary, 'strength_snapshot' => $m->strength_cp,
                    'bot_personality' => $personalities[crc32($league->id.':'.$m->id) % count($personalities)], 'created_at' => $now, 'updated_at' => $now,
                ]);
                $players = $m->source === NationSquad::SOURCE
                    ? NationSquad::pick((string) $m->nation, $version, $taken)
                    : DB::table('master_players')->where('master_club_id', $m->id)->pluck('id')->map(fn ($id) => (int) $id)->all();
                $rows = DB::table('master_players')->whereIn('id', $players)->get(['id', 'overall', 'value', 'line']);
                // A national team whose players the chosen clubs took is too short to play.
                if ($m->source === NationSquad::SOURCE && ($rows->count() < config('game.tournaments.nation_min_players') || ! $rows->contains('line', 'gk'))) {
                    throw new HttpException(422, sprintf(__('لا يكفي منتخب %s لاعبوه بعد أن أخذت الأندية المختارة لاعبيها. أزل بعض الأندية أو المنتخب.'), $m->name));
                }
                $insert = [];
                foreach ($rows as $p) {
                    $taken[$p->id] = true;
                    $insert[] = ['league_id' => $league->id, 'club_id' => $clubId, 'master_player_id' => $p->id, 'overall' => $p->overall,
                        'base_value' => $p->value, 'value' => $p->value, 'created_at' => $now, 'updated_at' => $now];
                }
                foreach (array_chunk($insert, 100) as $chunk) {
                    DB::table('players')->insert($chunk);
                }
                // A national team's strength from the squad it really got.
                if ($m->source === NationSquad::SOURCE && $rows->count()) {
                    $best = $rows->pluck('overall')->sortDesc()->take(18);
                    DB::table('clubs')->where('id', $clubId)->update(['strength_snapshot' => intdiv($best->sum() * 100, $best->count())]);
                }
                ClubLedger::post($clubId, 'opening', $s['starting_budget'], "opening:{$clubId}:1", 'season:1');
                $made[$m->id] = $clubId;
            }
            $league = $league->fresh();
            SeasonScheduler::build($league, $season->fresh());
            if (! empty($s['draw_at'])) {
                LiveDraw::schedule($league, $s['draw_at']);
            }
            if (isset($s['club_id'])) {
                Joining::claim($owner, $league->fresh(), $made[(int) $s['club_id']]);
            }

            return $league->fresh();
        });
    }

    /** Its price in coins: as a customized league of as many teams (free for a development tournament). */
    public static function cost(int $teams, array $s): int
    {
        return ($s['is_dev'] ?? false) ? 0 : LeagueTiers::cost($teams);
    }

    /** The shape fits the count: groups of at least two, and a knockout of 2, 4, 8 or 16 after them. */
    public static function assertShape(int $teams, array $s): void
    {
        $c = config('game.tournaments');
        if ($teams < $c['min_teams'] || $teams > $c['max_teams']) {
            throw new HttpException(422, sprintf(__('البطولة من %d إلى %d فريقاً.'), $c['min_teams'], $c['max_teams']));
        }
        if (! in_array($s['format'], TournamentPlan::FORMATS, true)) {
            throw new HttpException(422, __('اختر نظام البطولة.'));
        }
        if ($s['format'] === 'groups') {
            $g = (int) ($s['group_count'] ?? 0);
            $a = (int) ($s['advance_per_group'] ?? 2);
            if (! in_array($g, $c['group_counts'], true) || ! in_array($a, $c['advance'], true)) {
                throw new HttpException(422, __('عدد المجموعات 1 أو 2 أو 4 أو 8، والمتأهلون من كل مجموعة 1 أو 2.'));
            }
            if (intdiv($teams, $g) < 2 || intdiv($teams, $g) < $a || $g * $a < 2) {
                throw new HttpException(422, __('الفرق لا تكفي هذه المجموعات: فريقان على الأقل في كل مجموعة، ومتأهلان على الأقل للأدوار الإقصائية.'));
            }
        }
    }
}
