<?php

namespace App\Season;

use App\League\ClubLedger;
use App\League\LeagueFactory;
use App\League\SeasonScheduler;
use App\League\Standings;
use App\Messages\Inbox;
use App\Models\League;
use App\Models\Season;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Support\Facades\DB;

/**
 * The end of a season [PLAN 2.11, Sprint 33]: when its last match is in, the titles are given (the league's first
 * three, the cup's winner and finalist), every objective is judged, each coach is told how his season went; then,
 * by the league's setting, a new season starts at once from scratch, or the league ends.
 *
 * From scratch [PLAN 2.11]: the clubs get their own players back as the data has them, the starting budget, an empty
 * stadium, no training, no deals. What stays: the titles, the objectives judged, the settings and the coaches.
 */
class SeasonEnd
{
    /** Every minute: the running seasons whose last match is in. */
    public static function due(): int
    {
        $n = 0;
        foreach (DB::table('seasons')->where('status', 'running')->pluck('id') as $id) {
            $open = DB::table('fixtures')->where('season_id', $id)->where('is_bye', false)->where('status', '!=', 'finished')->exists();
            if (! $open && DB::table('fixtures')->where('season_id', $id)->exists()) {
                $n += self::close((int) $id) ? 1 : 0;
            }
        }

        return $n;
    }

    /** Close one season, once. */
    public static function close(int $seasonId): bool
    {
        return DB::transaction(function () use ($seasonId) {
            $now = GameClock::now();
            if (DB::table('seasons')->where('id', $seasonId)->where('status', 'running')->update(['status' => 'finished', 'finished_at' => $now, 'updated_at' => $now]) !== 1) {
                return false;
            }
            $season = Season::findOrFail($seasonId);
            $league = League::findOrFail($season->league_id);
            $order = Standings::order($seasonId);
            self::titles($league, $season, $order);
            Objectives::judge($seasonId, $order);
            self::tell($league, $season, $order);
            if ($league->season_end_mode === 'renew') {
                self::renew($league, $season);
            } else {
                DB::table('leagues')->where('id', $league->id)->update(['status' => 'finished', 'updated_at' => $now]);
            }

            return true;
        });
    }

    private static function titles(League $league, Season $season, array $order): void
    {
        $now = GameClock::now();
        $coach = fn (int $club) => DB::table('clubs')->where('id', $club)->value('user_id');
        $rows = [];
        // [Sprint 27] A tournament in groups or a knockout is won in its final: no league places.
        $places = $league->kind === 'tournament' && $league->format !== 'league' ? [] : array_slice($order, 0, 3);
        foreach ($places as $i => $club) {
            $rows[] = ['league_id' => $league->id, 'season_id' => $season->id, 'user_id' => $coach($club), 'club_id' => $club,
                'competition' => 'league', 'position' => $i + 1, 'created_at' => $now, 'updated_at' => $now];
        }
        $final = DB::table('cup_ties')->where('season_id', $season->id)->where('stage', 'final')->first();
        if ($final?->winner_id) {
            $runner = $final->winner_id === $final->home_id ? $final->away_id : $final->home_id;
            foreach ([1 => $final->winner_id, 2 => $runner] as $pos => $club) {
                $rows[] = ['league_id' => $league->id, 'season_id' => $season->id, 'user_id' => $coach($club), 'club_id' => $club,
                    'competition' => 'cup', 'position' => $pos, 'created_at' => $now, 'updated_at' => $now];
            }
        }
        DB::table('titles')->insertOrIgnore($rows);
        // Coins for the titles [docs/features/premium.md].
        foreach ($rows as $r) {
            Wallet::earn($r['user_id'], 'title', "title:{$season->id}:{$r['competition']}:{$r['position']}", "season:{$season->id}", $league->id, $season->id, "{$r['competition']}_{$r['position']}");
        }
    }

    /** Each coach hears where he finished and whether he met his objectives. */
    private static function tell(League $league, Season $season, array $order): void
    {
        $places = array_flip($order);
        foreach (DB::table('clubs')->where('league_id', $league->id)->whereNotNull('user_id')->get() as $club) {
            $o = DB::table('club_objectives')->where('club_id', $club->id)->where('season_id', $season->id)->get()->keyBy('competition');
            Inbox::send($club->user_id, 'season_end', [
                'league' => $league->name, 'season' => $season->number, 'place' => ($places[$club->id] ?? 0) + 1,
                'league_goal' => isset($o['league']) ? (bool) $o['league']->achieved : null,
                'cup_goal' => isset($o['cup']) ? (bool) $o['cup']->achieved : null,
                'champion' => ($places[$club->id] ?? -1) === 0, 'renew' => $league->season_end_mode === 'renew',
            ], $league->id, $club->id);
        }
    }

    /** The next season, from scratch, starting now with its preparation. */
    private static function renew(League $league, Season $old): void
    {
        $now = GameClock::now();
        $season = Season::create([
            'league_id' => $league->id, 'number' => $old->number + 1, 'starts_at' => $now, 'status' => 'running',
            'rounds' => $old->rounds, 'lock_from_round' => LeagueFactory::lockFromRound($old->rounds),
        ]);
        $clubs = DB::table('clubs')->where('league_id', $league->id)->get();
        $byMaster = $clubs->pluck('id', 'master_club_id');
        // [X62] Every loan still running ends with the season: its player goes home first.
        foreach (DB::table('player_loans')->where('season_id', $old->id)->where('status', 'active')->get() as $l) {
            DB::table('players')->where('id', $l->player_id)->where('club_id', $l->borrower_club_id)->update(['club_id' => $l->owner_club_id]);
            DB::table('player_loans')->where('id', $l->id)->update(['status' => 'returned', 'updated_at' => $now]);
        }
        // The players: each back with his own club as the data has him; the rest leave the league's clubs.
        // [X62 E1] Except a player whose renewed contract runs into the new season: he stays with his club, with his
        // rating, training and value; only his fitness, injuries and bans start again.
        foreach (DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('players.league_id', $league->id)->get(['players.id', 'players.club_id', 'players.contract_until', 'master_players.master_club_id', 'master_players.overall', 'master_players.value']) as $p) {
            if ($p->club_id && $p->contract_until !== null && (int) $p->contract_until >= $season->number) {
                DB::table('players')->where('id', $p->id)->update(['fitness' => 100, 'injured_matches' => 0, 'suspended_matches' => 0, 'training_progress' => 0,
                    'in_pool' => false, 'scouted_by' => null, 'sell_on_club_id' => null, 'sell_on_bp' => null, 'updated_at' => $now]);

                continue;
            }
            DB::table('players')->where('id', $p->id)->update([
                'contract_until' => null, 'sell_on_club_id' => null, 'sell_on_bp' => null,
                'club_id' => $byMaster[$p->master_club_id] ?? null, 'overall' => $p->overall, 'base_value' => $p->value, 'value' => $p->value,
                'training_bonus' => 0, 'training_progress' => 0, 'fitness' => 100, 'injured_matches' => 0, 'suspended_matches' => 0,
                'in_pool' => false, 'scouted_by' => null, 'updated_at' => $now,
            ]);
        }
        $ids = $clubs->pluck('id')->all();
        // No training, camp, stadium, specialist or deal carries over; lineups go back to automatic.
        DB::table('training_slots')->whereIn('club_id', $ids)->delete();
        DB::table('training_camps')->whereIn('club_id', $ids)->where('status', 'active')->update(['status' => 'done', 'updated_at' => $now]);
        DB::table('stadium_builds')->whereIn('club_id', $ids)->where('status', 'building')->delete();
        DB::table('stadium_sections')->whereIn('club_id', $ids)->delete();
        DB::table('staff_specialists')->whereIn('club_id', $ids)->where('ends_at', '>', $now)->update(['ends_at' => $now, 'updated_at' => $now]);
        DB::table('transfer_listings')->whereIn('club_id', $ids)->delete();
        DB::table('transfer_offers')->whereIn('from_club_id', $ids)->where('status', 'pending')->update(['status' => 'cancelled', 'updated_at' => $now]);
        DB::table('lineups')->whereIn('club_id', $ids)->delete();
        // The money: the season's balance closes, and the starting budget opens the new one.
        foreach ($clubs as $c) {
            $balance = ClubLedger::sum($c->id);
            if ($balance !== 0) {
                ClubLedger::post($c->id, 'season_close', -$balance, "season_close:{$c->id}:{$old->number}", "season:{$old->number}");
            }
            ClubLedger::post($c->id, 'opening', (int) $league->starting_budget, "opening:{$c->id}:{$season->number}", "season:{$season->number}");
            DB::table('clubs')->where('id', $c->id)->update(['debt_rounds' => 0, 'updated_at' => $now]);
        }
        // The coaches stay with their clubs.
        foreach (DB::table('league_memberships')->where('season_id', $old->id)->whereNull('left_at')->get() as $m) {
            DB::table('league_memberships')->insert(['league_id' => $league->id, 'season_id' => $season->id, 'user_id' => $m->user_id, 'club_id' => $m->club_id,
                'joined_at' => $now, 'last_active_at' => $now, 'created_at' => $now, 'updated_at' => $now]);
        }
        SeasonScheduler::build($league->fresh(), $season->fresh());
        Objectives::set($season->id);
    }
}
