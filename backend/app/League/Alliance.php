<?php

namespace App\League;

use App\Models\League;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Random\Engine\Mt19937;
use Random\Randomizer;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * The alliance tournament [X27]. The league's owner names two captains, the size of each alliance (2 to 7,
 * 5 by default) and the first round's time; the coaches are shared out at random, the captains each in his
 * own. It goes to the developers, and starts only once they approve it.
 *
 * A knockout drawn afresh each round so team-mates do not meet: every coach of one alliance is drawn against
 * one of the other while both have coaches left. Team-mates left over are not played: their captain picks who
 * goes on (or, if he has not by the round's time, the stronger club); an odd number gives one of them a bye.
 * Once only one alliance has coaches left (a final between team-mates too), the title is its own.
 * The matches are league fixtures (competition "alliance") played as knockout ties, with extra time and penalties.
 */
class Alliance
{
    public static function create(League $league, User $owner, array $data): int
    {
        if (DB::table('alliance_tournaments')->where('league_id', $league->id)->whereIn('status', ['pending', 'running'])->exists()) {
            throw new HttpException(409, 'في الدوري بطولة تحالفات قائمة أو تنتظر الاعتماد.');
        }
        $size = (int) $data['size'];
        $coaches = DB::table('clubs')->join('users', 'users.id', '=', 'clubs.user_id')->where('clubs.league_id', $league->id)
            ->get(['clubs.id', 'clubs.user_id', 'users.username'])->keyBy(fn ($c) => strtolower((string) $c->username));
        $a = $coaches[strtolower($data['captain_a'])] ?? null;
        $b = $coaches[strtolower($data['captain_b'])] ?? null;
        if (! $a || ! $b || $a->id === $b->id) {
            throw new HttpException(422, 'القائدان مدربان مختلفان في هذا الدوري، باسم المستخدم.');
        }
        if ($coaches->count() < 2 * $size) {
            throw new HttpException(422, "تحالفان من {$size} يحتاجان ".(2 * $size).' مدربين في الدوري، وفيه '.$coaches->count().'.');
        }
        $at = Carbon::parse($data['first_round_at'])->utc();
        if ($at->lte(GameClock::now()->addMinutes((int) config('game.alliance.notice_minutes')))) {
            throw new HttpException(422, 'موعد الدور الأول بعد '.config('game.alliance.notice_minutes').' دقيقة على الأقل، ليتسع وقت الاعتماد.');
        }
        $seed = random_int(1, 2_147_483_647);
        // The others shared out at random by the creator's draw: the captains each in his own alliance.
        $others = (new Randomizer(new Mt19937($seed)))->shuffleArray($coaches->reject(fn ($c) => in_array($c->id, [$a->id, $b->id], true))->pluck('id')->all());
        $teams = ['a' => [$a->id, ...array_slice($others, 0, $size - 1)], 'b' => [$b->id, ...array_slice($others, $size - 1, $size - 1)]];
        $now = GameClock::now();

        return DB::transaction(function () use ($league, $data, $size, $a, $b, $at, $seed, $teams, $now) {
            $id = DB::table('alliance_tournaments')->insertGetId([
                'league_id' => $league->id, 'season_id' => $league->season->id, 'name' => trim($data['name']), 'status' => 'pending', 'size' => $size,
                'captain_a' => $a->user_id, 'captain_b' => $b->user_id, 'first_round_at' => $at,
                'round_gap_minutes' => $league->is_dev ? (int) config('game.alliance.dev_gap_minutes') : (int) config('game.alliance.gap_minutes'),
                'seed' => $seed, 'created_at' => $now, 'updated_at' => $now,
            ]);
            foreach ($teams as $alliance => $clubs) {
                foreach ($clubs as $club) {
                    DB::table('alliance_members')->insert(['tournament_id' => $id, 'club_id' => $club, 'alliance' => $alliance]);
                }
            }

            return $id;
        });
    }

    /** The developers' call. Approved, it draws its first round. */
    public static function review(int $id, User $admin, bool $approve, ?string $note = null): void
    {
        DB::transaction(function () use ($id, $admin, $approve, $note) {
            $now = GameClock::now();
            $changed = DB::table('alliance_tournaments')->where('id', $id)->where('status', 'pending')->update([
                'status' => $approve ? 'running' : 'rejected', 'reviewed_by' => $admin->id, 'reviewed_at' => $now, 'review_note' => $note, 'updated_at' => $now,
            ]);
            if ($changed !== 1) {
                throw new HttpException(409, 'البطولة ليست بانتظار الاعتماد.');
            }
            if ($approve) {
                $t = DB::table('alliance_tournaments')->where('id', $id)->first();
                $at = Carbon::parse($t->first_round_at, 'UTC');
                // Approved late: the first round moves to a moment still to come.
                $at = $at->lt($now->copy()->addMinutes(10)) ? $now->copy()->addMinutes(10) : $at;
                self::drawRound($t, 1, DB::table('alliance_members')->where('tournament_id', $id)->pluck('alliance', 'club_id')->all(), $at);
            }
        });
    }

    /**
     * The pure draw of one round.
     *
     * @param  array<int, string>  $entrants  club => alliance (a|b)
     * @return list<array{kind: string, home: int, away: ?int}>
     */
    public static function pair(array $entrants, int $seed): array
    {
        ksort($entrants);
        $rng = new Randomizer(new Mt19937($seed));
        $a = $rng->shuffleArray(array_keys(array_filter($entrants, fn ($x) => $x === 'a')));
        $b = $rng->shuffleArray(array_keys(array_filter($entrants, fn ($x) => $x === 'b')));
        if (count($entrants) === 2) {
            $ids = array_keys($entrants);

            return [['kind' => count($a) === 1 ? 'match' : 'walkover', 'home' => $ids[0], 'away' => $ids[1]]];
        }
        $ties = [];
        $cross = min(count($a), count($b));
        for ($i = 0; $i < $cross; $i++) {
            $ties[] = ['kind' => 'match', 'home' => $i % 2 ? $b[$i] : $a[$i], 'away' => $i % 2 ? $a[$i] : $b[$i]];
        }
        // Those left over are of one alliance. An odd number gives one of them a bye.
        $left = [...array_slice($a, $cross), ...array_slice($b, $cross)];
        if (count($left) % 2 === 1) {
            $ties[] = ['kind' => 'bye', 'home' => array_shift($left), 'away' => null];
        }
        foreach (array_chunk($left, 2) as [$home, $away]) {
            $ties[] = ['kind' => 'captain', 'home' => $home, 'away' => $away];
        }

        return $ties;
    }

    private static function drawRound(object $t, int $round, array $entrants, Carbon $at): void
    {
        $at = self::freeAt($t->season_id, array_keys($entrants), $at);
        $now = GameClock::now();
        $walkover = null;
        foreach (self::pair($entrants, (int) $t->seed + $round) as $tie) {
            $fixture = null;
            if ($tie['kind'] === 'match') {
                $fixture = DB::table('fixtures')->insertGetId(['season_id' => $t->season_id, 'competition' => 'alliance', 'round' => $round, 'scheduled_at' => $at,
                    'home_id' => $tie['home'], 'away_id' => $tie['away'], 'is_bye' => false, 'created_at' => $now, 'updated_at' => $now]);
            }
            DB::table('alliance_ties')->insert(['tournament_id' => $t->id, 'round' => $round, 'kind' => $tie['kind'], 'home_id' => $tie['home'], 'away_id' => $tie['away'],
                'fixture_id' => $fixture, 'scheduled_at' => $at, 'winner_id' => $tie['kind'] === 'bye' ? $tie['home'] : null, 'created_at' => $now, 'updated_at' => $now]);
            if ($tie['kind'] === 'walkover') {
                $walkover = $entrants[$tie['home']];
            }
        }
        if ($walkover) {
            self::finish($t->id, $walkover);
        }
    }

    /** A time when none of these clubs has another match within the gap: an hour later each time. */
    private static function freeAt(int $seasonId, array $clubs, Carbon $at): Carbon
    {
        $gap = (int) config('game.alliance.clash_minutes');
        for ($i = 0; $i < 72; $i++) {
            $busy = DB::table('fixtures')->where('season_id', $seasonId)->where('is_bye', false)
                ->whereBetween('scheduled_at', [$at->copy()->subMinutes($gap), $at->copy()->addMinutes($gap)])
                ->where(fn ($q) => $q->whereIn('home_id', $clubs)->orWhereIn('away_id', $clubs))->exists();
            if (! $busy) {
                return $at;
            }
            $at = $at->copy()->addMinutes(60);
        }

        return $at;
    }

    /** A captain's pick between two of his coaches, until it is decided. */
    public static function decide(int $tieId, User $user, int $winner): void
    {
        $tie = DB::table('alliance_ties')->where('id', $tieId)->first();
        if (! $tie || $tie->kind !== 'captain' || $tie->winner_id) {
            throw new HttpException(409, 'هذه المواجهة ليست بانتظار قرار القائد.');
        }
        $t = DB::table('alliance_tournaments')->where('id', $tie->tournament_id)->first();
        $alliance = DB::table('alliance_members')->where('tournament_id', $t->id)->where('club_id', $tie->home_id)->value('alliance');
        if ((int) ($alliance === 'a' ? $t->captain_a : $t->captain_b) !== $user->id) {
            throw new HttpException(403, 'القرار لقائد التحالف.');
        }
        if (! in_array($winner, [(int) $tie->home_id, (int) $tie->away_id], true)) {
            throw new HttpException(422, 'اختر أحد المدربين في هذه المواجهة.');
        }
        DB::table('alliance_ties')->where('id', $tieId)->whereNull('winner_id')->update(['winner_id' => $winner, 'updated_at' => GameClock::now()]);
        self::advance($t->id);
    }

    /** A played tie is over: its winner, after extra time and penalties if need be. */
    public static function fixtureDone(object $f, array $state): void
    {
        $score = $state['score'];
        $won = $score['home'] === $score['away'] ? ($state['shootout'] ?? $score) : $score;
        $winner = $won['home'] > $won['away'] ? $f->home_id : $f->away_id;
        $tie = DB::table('alliance_ties')->where('fixture_id', $f->id)->first();
        if (! $tie) {
            return;
        }
        DB::table('alliance_ties')->where('id', $tie->id)->update(['winner_id' => $winner, 'updated_at' => GameClock::now()]);
        self::advance($tie->tournament_id);
    }

    /** Every minute: the captains' picks not made by the round's time go to the stronger club; then the next rounds. */
    public static function tick(): int
    {
        $n = 0;
        $late = DB::table('alliance_ties')->join('alliance_tournaments', 'alliance_tournaments.id', '=', 'alliance_ties.tournament_id')
            ->where('alliance_tournaments.status', 'running')->where('alliance_ties.kind', 'captain')->whereNull('alliance_ties.winner_id')
            ->where('alliance_ties.scheduled_at', '<=', GameClock::now())->get(['alliance_ties.*']);
        foreach ($late as $tie) {
            $strength = DB::table('clubs')->whereIn('id', [$tie->home_id, $tie->away_id])->orderByDesc('strength_snapshot')->orderBy('id')->value('id');
            DB::table('alliance_ties')->where('id', $tie->id)->whereNull('winner_id')->update(['winner_id' => $strength, 'updated_at' => GameClock::now()]);
            self::advance($tie->tournament_id);
            $n++;
        }

        return $n;
    }

    /** When every tie of the last round has its winner: the champion, or the next round. */
    private static function advance(int $id): void
    {
        $t = DB::table('alliance_tournaments')->where('id', $id)->first();
        if ($t->status !== 'running') {
            return;
        }
        $round = (int) DB::table('alliance_ties')->where('tournament_id', $id)->max('round');
        $ties = DB::table('alliance_ties')->where('tournament_id', $id)->where('round', $round)->get();
        if ($ties->contains(fn ($x) => $x->winner_id === null)) {
            return;
        }
        $alliances = DB::table('alliance_members')->where('tournament_id', $id)->pluck('alliance', 'club_id')->all();
        $winners = $ties->pluck('winner_id')->map(fn ($w) => (int) $w)->all();
        // One alliance left (its last coach, or only its coaches): the title is its own, nothing more to play.
        $left = array_values(array_unique(array_map(fn ($w) => $alliances[$w], $winners)));
        if (count($left) === 1) {
            self::finish($id, $left[0]);

            return;
        }
        $at = Carbon::parse($ties->max('scheduled_at'), 'UTC')->addMinutes((int) $t->round_gap_minutes);
        self::drawRound($t, $round + 1, array_intersect_key($alliances, array_flip($winners)), $at);
    }

    private static function finish(int $id, string $alliance): void
    {
        DB::table('alliance_tournaments')->where('id', $id)->where('status', 'running')
            ->update(['status' => 'finished', 'winner' => $alliance, 'updated_at' => GameClock::now()]);
    }
}
