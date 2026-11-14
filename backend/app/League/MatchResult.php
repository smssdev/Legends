<?php

namespace App\League;

use App\Database\Sql;
use App\Economy\Economy;
use App\Experience\PlayerMilestones;
use App\Market\Loans;
use App\Market\Market;
use App\Messenger\LeagueGroups;
use App\Season\Achievements;
use App\Season\CoachRating;
use App\Staff\Specialists;
use App\Support\GameClock;
use App\Tournament\TournamentStage;
use App\Wallet\Wallet;
use Illuminate\Support\Facades\DB;

/**
 * What a finished match leaves behind [PLAN 2.8, 2.12, Sprint 18 B5]:
 *  - the fixture's result (the table reads it), the rounds played, and in the cup the winner moving on;
 *  - each club's numbers (match_stats);
 *  - on the players: those who played end with the fitness they finished with, those who rested get some
 *    back; then every injury and suspension of these two clubs counts this match down by one, and the
 *    new ones begin (an injury lasts 1 to 3 of the club's matches, from the match's seed; a red card 1).
 *    "The next match" is the club's next match in any competition;
 *  - each coach's report, "why you won or lost" (MatchReport).
 */
class MatchResult
{
    public static function apply(int $matchId): void
    {
        $m = DB::table('matches')->where('id', $matchId)->first();
        $f = DB::table('fixtures')->where('id', $m->fixture_id)->first();
        $state = json_decode($m->state, true);
        $now = GameClock::now();
        $club = ['home' => $f->home_id, 'away' => $f->away_id];

        Standings::forget((int) $f->season_id);
        DB::table('fixtures')->where('id', $f->id)->update(['status' => 'finished', 'home_goals' => $state['score']['home'],
            'away_goals' => $state['score']['away'], 'updated_at' => $now]);

        // [Sprint 68] A league group's poll on this match: closed, and its answer posted.
        LeagueGroups::fixtureDone($f);
        // [UP12] The coaches' predictions of this match.
        Predictions::settle($f, (int) $state['score']['home'], (int) $state['score']['away']);
        if ($f->competition === 'league') {
            self::roundsPlayed($f->season_id);
        } elseif ($f->competition === 'alliance') {
            Alliance::fixtureDone($f, $state);
        } else {
            self::cupWinner($f, $state);
        }
        // The money it moves: gate, wages, bonus and the debt count [Sprint 23].
        Economy::afterMatch($f, $state['score']);
        // A bot left short (a forced sale) buys what it lacks from the pool [Sprint 24].
        foreach ([$f->home_id, $f->away_id] as $clubId) {
            Market::refill($clubId);
        }

        foreach (['home', 'away'] as $side) {
            $team = $state['teams'][$side];
            DB::table('match_stats')->insertOrIgnore([
                'match_id' => $matchId, 'club_id' => $club[$side], 'counters' => json_encode($team['stats']),
                'players' => json_encode(array_map(fn ($p) => ['id' => $p['id'], 'played' => $p['on'] || $p['out'] !== '',
                    'fit' => intdiv($p['fit'], 100), 'rating' => $p['st']['r'], 'goals' => $p['st']['goals'], 'assists' => $p['st']['assists'],
                    'yc' => $p['yc'], 'out' => $p['out']], $team['players'])),
            ]);
            self::players($club[$side], $team, $m->seed, $matchId);
            // [Sprint 64 B8] The milestones its players reached with the club.
            PlayerMilestones::after($matchId, (int) $club[$side], $state);
            // Morale after the result [X25].
            // [Sprint 49] With the strength gap at kick-off (the other's minus ours), for a draw against a stronger side.
            $strength = DB::table('clubs')->whereIn('id', [$club['home'], $club['away']])->pluck('strength_snapshot', 'id');
            $gap = (int) ($strength[$club[$side === 'home' ? 'away' : 'home']] ?? 0) - (int) ($strength[$club[$side]] ?? 0);
            Morale::after($club[$side], $state['score'][$side], $state['score'][$side === 'home' ? 'away' : 'home'], $gap);
            // [X61 E9] And the press statement, judged by the result.
            PressRoom::judge($f, $club[$side], $state['score'][$side], $state['score'][$side === 'home' ? 'away' : 'home']);
            // Coins for the coach: a win or a draw [docs/features/premium.md].
            $for = $state['score'][$side];
            $against = $state['score'][$side === 'home' ? 'away' : 'home'];
            $league = (int) DB::table('seasons')->where('id', $f->season_id)->value('league_id');
            if ($for >= $against) {
                $type = $for > $against ? 'win' : 'draw';
                Wallet::earn(DB::table('clubs')->where('id', $club[$side])->value('user_id'), $type, "{$type}:{$f->id}:{$club[$side]}", "fixture:{$f->id}", $league, $f->season_id);
            } else {
                self::upsetLoss($f, (int) $club[$side], (int) $club[$side === 'home' ? 'away' : 'home'], $league);
            }
        }
        MatchReport::store($matchId, $state);
        // [Sprint 40 A1] A badge reached with this match (the first win, the tenth match...) pays its coins now.
        foreach ($club as $id) {
            Achievements::award(DB::table('clubs')->where('id', $id)->value('user_id'));
        }
    }

    /**
     * [Sprint 43 C1] A coach beaten by a coach of a lower rating tier pays upset_loss coins (all he has, if fewer). Both
     * sides coached by people; once by its key.
     */
    private static function upsetLoss(object $f, int $loserClub, int $winnerClub, int $league): void
    {
        $loser = DB::table('clubs')->where('id', $loserClub)->value('user_id');
        $winner = DB::table('clubs')->where('id', $winnerClub)->value('user_id');
        $coins = min((int) config('game.premium.upset_loss'), $loser ? Wallet::balance((int) $loser) : 0);
        if (! $loser || ! $winner || $coins <= 0) {
            return;
        }
        if (CoachRating::of((int) $loser)['tier']['rank'] > CoachRating::of((int) $winner)['tier']['rank']) {
            Wallet::post((int) $loser, 'upset_loss', -$coins, "upset_loss:{$f->id}:{$loserClub}", "fixture:{$f->id}", $league, $f->season_id);
        }
    }

    private static function players(int $clubId, array $team, int $seed, int $matchId): void
    {
        $played = [];
        foreach ($team['players'] as $p) {
            if ($p['on'] || $p['out'] !== '') {
                $played[$p['id']] = intdiv($p['fit'], 100);
            }
        }
        // The specialists under contract now [docs/features/specialists.md].
        // Each by his stars [X20].
        $lawyer = Specialists::has($clubId, 'lawyer');
        $rest = (int) config('game.matches.rest_recovery') + Specialists::effect($clubId, 'physio', 'physio_rest_bonus');
        // Fitness: as they ended and a little back before the next match [X21], or a rest.
        $back = (int) config('game.matches.played_recovery');
        foreach ($played as $id => $fit) {
            DB::table('players')->where('id', $id)->update(['fitness' => max(0, min(100, $fit + $back))]);
        }
        DB::table('players')->where('club_id', $clubId)->whereNotIn('id', array_keys($played))
            ->update(['fitness' => Sql::least("fitness + {$rest}", 100)]);
        // This match counts down every absence of the club's players...
        $heal = Specialists::effect($clubId, 'doctor', 'doctor_countdown', 1);
        DB::table('players')->where('club_id', $clubId)->where('injured_matches', '>', 0)
            ->update(['injured_matches' => Sql::greatest("injured_matches - {$heal}", 0)]);
        DB::table('players')->where('club_id', $clubId)->where('suspended_matches', '>', 0)->decrement('suspended_matches');
        // ...then the new ones start.
        $events = DB::table('match_events')->where('match_id', $matchId)->where('club_id', $clubId)->whereIn('type', ['injury', 'card'])->get();
        [$min, $max] = config('game.matches.injury_matches');
        foreach ($events as $e) {
            $payload = json_decode($e->payload, true);
            $player = $payload['player'] ?? null;
            if (! $player) {
                continue;
            }
            if ($e->type === 'injury') {
                $n = $min + crc32("{$seed}:{$player}") % ($max - $min + 1);
                DB::table('players')->where('id', $player)->update(['injured_matches' => Sql::greatest('injured_matches', $n)]);
            } elseif (($payload['color'] ?? null) === 'red' && ! ($lawyer && Specialists::lawyerCancels($clubId, $seed, (int) $player))) {
                DB::table('players')->where('id', $player)->update(['suspended_matches' => DB::raw('suspended_matches + '.(int) config('game.matches.red_card_matches'))]);
            }
        }
    }

    /** League rounds played: the rounds whose matches have all ended, in order. */
    private static function roundsPlayed(int $seasonId): void
    {
        $open = DB::table('fixtures')->where('season_id', $seasonId)->where('competition', 'league')->where('is_bye', false)
            ->where('status', '!=', 'finished')->min('round');
        $rounds = (int) DB::table('seasons')->where('id', $seasonId)->value('rounds');
        DB::table('seasons')->where('id', $seasonId)->update(['rounds_played' => $open ? $open - 1 : $rounds]);
        // [Sprint 67] A round just ended: its results to the league's Telegram group, if it has one.
        LeagueGroups::roundDone($seasonId);
        // [X61 E2] Loans whose last round is played send their players home.
        Loans::returnDue($seasonId);
        // The last league match is in: the prizes by final place (each paid once, by its key).
        if (! $open) {
            // [Sprint 29] A tournament's groups are over: the knockout is filled from their tables (no league prizes).
            $league = DB::table('leagues')->join('seasons', 'seasons.league_id', '=', 'leagues.id')->where('seasons.id', $seasonId)->first(['leagues.kind', 'leagues.format']);
            if ($league?->kind === 'tournament' && $league->format === 'groups') {
                TournamentStage::groupsDone($seasonId);

                return;
            }
            Economy::leaguePrizes($seasonId, Standings::order($seasonId));
        }
    }

    /** The cup: the winner (after extra time, or on penalties) takes his side of the next tie. */
    private static function cupWinner(object $f, array $state): void
    {
        $score = $state['score'];
        $won = $score['home'] === $score['away'] ? ($state['shootout'] ?? $score) : $score;
        $winner = $won['home'] > $won['away'] ? $f->home_id : $f->away_id;
        $tie = DB::table('cup_ties')->where('fixture_id', $f->id)->first();
        if (! $tie) {
            return;
        }
        DB::table('cup_ties')->where('id', $tie->id)->update(['winner_id' => $winner]);
        Economy::cupPrizes($tie, $winner, $winner === $f->home_id ? $f->away_id : $f->home_id);
        if ($tie->next_tie_id) {
            $side = $tie->next_side === 'home' ? 'home_id' : 'away_id';
            DB::table('cup_ties')->where('id', $tie->next_tie_id)->update([$side => $winner]);
            $next = DB::table('cup_ties')->where('id', $tie->next_tie_id)->value('fixture_id');
            DB::table('fixtures')->where('id', $next)->update([$side => $winner]);
        }
    }
}
