<?php

namespace App\League;

use App\Messages\Inbox;
use App\Simulator\Report;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;

/**
 * "Why you won or lost" for each coach of a finished league match [ENGINE 8.1, Sprint 20 B2]: the simulator's
 * report, built here from MatchFacts (public counts and the coach's own side) and the stored public events,
 * with the readings his assistant gave him during the match. Kept in match_reports, one per club.
 */
class MatchReport
{
    public const TIMELINE = ['goal', 'card', 'sub', 'injury', 'penalty'];

    public static function store(int $matchId, array $state): void
    {
        $f = DB::table('fixtures')->join('matches', 'matches.fixture_id', '=', 'fixtures.id')->where('matches.id', $matchId)
            ->join('seasons', 'seasons.id', '=', 'fixtures.season_id')->select('fixtures.home_id', 'fixtures.away_id', 'seasons.league_id')->first();
        $club = ['home' => $f->home_id, 'away' => $f->away_id];
        $timeline = self::timeline($matchId, $club);
        foreach ($club as $side => $clubId) {
            $report = self::build(MatchFacts::of($state, $side), $timeline);
            $report['readings'] = DB::table('match_readings')->where('match_id', $matchId)->where('club_id', $clubId)
                ->orderBy('tick')->get(['minute', 'kind', 'text'])->map(fn ($r) => (array) $r)->all();
            $new = DB::table('match_reports')->insertOrIgnore(['match_id' => $matchId, 'club_id' => $clubId,
                'report' => json_encode($report), 'created_at' => GameClock::now()]);
            if ($new) {
                // The coach hears his report is ready [Sprint 22].
                $other = $side === 'home' ? 'away' : 'home';
                Inbox::send(Inbox::coachOf($clubId), 'match_report', ['match_id' => $matchId, 'result' => $report['result'],
                    'opponent' => $state['teams'][$other]['club']['name'], 'score' => $state['score'][$side].' - '.$state['score'][$other]],
                    $f->league_id, $clubId);
            }
        }
    }

    /** The report from what this coach may know: MatchFacts holds no tactics to read. */
    public static function build(array $facts, array $timeline): array
    {
        return ['timeline' => $timeline] + Report::build($facts, [], $facts['side']);
    }

    /** The match's big moments from its stored events, in order. */
    private static function timeline(int $matchId, array $club): array
    {
        return DB::table('match_events')->where('match_id', $matchId)->whereIn('type', self::TIMELINE)->orderBy('id')->get()
            ->map(fn ($e) => ['minute' => (int) $e->minute, 'type' => $e->type,
                'team' => $e->club_id === null ? null : ($e->club_id === $club['home'] ? 'home' : 'away')]
                + array_diff_key(json_decode($e->payload, true), ['text' => 1]))->all();
    }
}
