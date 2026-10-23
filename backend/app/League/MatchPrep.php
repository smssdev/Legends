<?php

namespace App\League;

use App\Engine\AutoPick;
use App\Messages\Inbox;
use App\Models\Club;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * Before a match [PLAN 2.13]. Thirty minutes before: the referee and his strictness, drawn on the server
 * and kept. Five minutes before, the lock: any injured or suspended starter is replaced by the best
 * substitute (the bench first, then the rest of the squad), then each side's lineup, takers and tactics
 * are frozen for the match. From then until the match ends the sheet cannot be edited.
 */
class MatchPrep
{
    /** Every minute. Returns [referees drawn, fixtures locked]. */
    public static function run(): array
    {
        $now = GameClock::now();
        $refs = 0;
        $due = DB::table('fixtures')->where('status', 'scheduled')->where('is_bye', false)->whereNull('referee_strictness')
            ->whereNotNull('home_id')->whereNotNull('away_id')
            ->where('scheduled_at', '<=', $now->copy()->addMinutes(config('game.match.referee_minutes_before')))->pluck('id');
        foreach ($due as $id) {
            $strictness = Tactics::REFEREES[random_int(0, 2)];
            $drawn = DB::table('fixtures')->where('id', $id)->whereNull('referee_strictness')
                ->update(['referee_strictness' => $strictness, 'referee_at' => $now, 'updated_at' => $now]);
            $refs += $drawn;
            if ($drawn) {
                self::tellCoaches($id, $strictness);
            }
        }
        $locks = 0;
        $due = DB::table('fixtures')->where('status', 'scheduled')->where('is_bye', false)->whereNotNull('home_id')->whereNotNull('away_id')
            ->where('scheduled_at', '<=', $now->copy()->addMinutes(config('game.match.lock_minutes_before')))->pluck('id');
        foreach ($due as $id) {
            $locks += self::lock($id) ? 1 : 0;
        }

        return [$refs, $locks];
    }

    /** The referee goes to both coaches' inboxes [PLAN 2.13, Sprint 22 B2]. */
    private static function tellCoaches(int $fixtureId, string $strictness): void
    {
        $f = DB::table('fixtures')->join('seasons', 'seasons.id', '=', 'fixtures.season_id')->join('leagues', 'leagues.id', '=', 'seasons.league_id')
            ->where('fixtures.id', $fixtureId)->select('fixtures.*', 'leagues.id as league_id', 'leagues.name as league')->first();
        $names = DB::table('clubs')->whereIn('id', [$f->home_id, $f->away_id])->pluck('name', 'id');
        foreach ([[$f->home_id, $f->away_id], [$f->away_id, $f->home_id]] as [$club, $other]) {
            Inbox::send(Inbox::coachOf($club), 'referee', ['league' => $f->league, 'opponent' => $names[$other] ?? '',
                'strictness' => $strictness, 'fixture_id' => $f->id, 'at' => $f->scheduled_at], $f->league_id, $club);
        }
    }

    /** Lock one fixture: fix and freeze both sides. False when another run got there first. */
    public static function lock(int $fixtureId): bool
    {
        return DB::transaction(function () use ($fixtureId) {
            $now = GameClock::now();
            $fixture = DB::table('fixtures')->where('id', $fixtureId)->first();
            $changed = DB::table('fixtures')->where('id', $fixtureId)->where('status', 'scheduled')
                ->update(['status' => 'locked', 'locked_at' => $now, 'updated_at' => $now,
                    // A match locked without its 30-minute call (the server was off) still gets a referee.
                    'referee_strictness' => $fixture->referee_strictness ?? Tactics::REFEREES[random_int(0, 2)]]);
            if ($changed !== 1) {
                return false;
            }
            foreach ([$fixture->home_id, $fixture->away_id] as $clubId) {
                $club = Club::find($clubId);
                // A bot picks its eleven afresh, resting the tired, and its tactics for this opponent [Sprint 32].
                [$lineup, $fixes] = $club->isBot() ? [TeamSheet::best($club, Bot::restBelow($club)), []] : self::fixed($club);
                DB::table('fixture_sheets')->insert([
                    'fixture_id' => $fixtureId, 'club_id' => $clubId, 'formation' => $lineup['formation'],
                    'slots' => json_encode($lineup['slots']), 'starters' => json_encode($lineup['starters']), 'bench' => json_encode($lineup['bench']),
                    'takers' => json_encode(TeamSheet::takers($club, $lineup)), 'tactics' => json_encode($club->isBot() ? Bot::tacticsFor($club, $fixture) : Tactics::of($club)),
                    'fixes' => json_encode($fixes), 'locked_at' => $now,
                ]);
            }

            return true;
        });
    }

    /**
     * The lineup with every injured, suspended or missing starter replaced by the best fit: from the bench
     * first, then the rest of the squad [PLAN 2.13].
     *
     * @return array{0: array, 1: list<array{slot: int, out: ?int, in: int}>}
     */
    public static function fixed(Club $club): array
    {
        $lineup = TeamSheet::current($club);
        $squad = collect(TeamSheet::squad($club))->keyBy('id');
        $fixes = [];
        foreach ($lineup['starters'] as $i => $id) {
            if ($id !== null && $squad->has($id) && ! $squad[$id]['unavailable']) {
                continue;
            }
            $used = array_flip(array_filter($lineup['starters']));
            $slot = $lineup['slots'][$i];
            $fit = ['line' => $slot['line'], 'fits' => TeamSheet::fits($slot['role'])];
            $score = fn ($p) => $p['a']['ovr'] * 100 - AutoPick::misfit($p, $fit);
            $pick = null;
            foreach ([$lineup['bench'], $squad->keys()->all()] as $pool) {
                foreach ($pool as $cand) {
                    $p = $squad[$cand] ?? null;
                    if (! $p || $p['unavailable'] || isset($used[$cand]) || ($pick && $score($p) <= $score($squad[$pick]))) {
                        continue;
                    }
                    $pick = $cand;
                }
                if ($pick) {
                    break;
                }
            }
            if ($pick) {
                $lineup['starters'][$i] = $pick;
                $lineup['bench'] = array_values(array_diff($lineup['bench'], [$pick]));
                $fixes[] = ['slot' => $i, 'out' => $id, 'in' => $pick];
            }
        }
        // Whoever is unavailable leaves the bench too.
        $lineup['bench'] = array_values(array_filter($lineup['bench'], fn ($id) => ! $squad[$id]['unavailable']));

        return [$lineup, $fixes];
    }

    /** The club's sheet is frozen from the lock until its match ends. */
    public static function assertOpen(Club $club): void
    {
        $locked = DB::table('fixtures')->whereIn('status', ['locked', 'live'])
            ->where(fn ($q) => $q->where('home_id', $club->id)->orWhere('away_id', $club->id))->exists();
        if ($locked) {
            throw new HttpException(409, 'التشكيلة والتكتيك مقفلان قبل المباراة بخمس دقائق وحتى نهايتها.');
        }
    }
}
