<?php

namespace App\League;

use App\Market\Transfers;
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
 *
 * [Sprint 40 D1, D2] The owner's (2026-11-03): two to ten teams in all, two equal alliances (1 to 5 each), planned as the
 * league is made (plan()): shared by the draw, or by the maker's own split by username, and formed form_minutes before
 * the first round (form(), the coaches who joined by then; a place nobody holds goes to a computer's club). Two coaches
 * of one alliance drawn together (when it cannot be helped) agree who goes on (decide()): both pick the same, or the
 * stronger at the round's time; the one who goes on may swap up to swap_max players with the other (swap()).
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
                'seed' => $seed, 'formed_at' => $now, 'created_at' => $now, 'updated_at' => $now,
            ]);
            foreach ($teams as $alliance => $clubs) {
                foreach ($clubs as $club) {
                    DB::table('alliance_members')->insert(['tournament_id' => $id, 'club_id' => $club, 'alliance' => $alliance]);
                }
            }

            return $id;
        });
    }

    /**
     * [Sprint 40 D1] Planned as the league is made: the size of each alliance, the draw or the maker's split (usernames
     * for a and b, up to the size each), and the first round's time (else a day after the league's first round).
     */
    public static function plan(League $league, User $owner, array $data): int
    {
        $size = (int) $data['size'];
        if ($size * 2 > (int) $league->team_count) {
            throw new HttpException(422, __('تحالفان من :n يحتاجان :t فرق في الدوري.', ['n' => $size, 't' => 2 * $size]));
        }
        $assign = ($data['assign'] ?? 'draw') === 'pick' ? 'pick' : 'draw';
        $plan = ['a' => [], 'b' => []];
        if ($assign === 'pick') {
            foreach (['a', 'b'] as $side) {
                $plan[$side] = collect($data[$side] ?? [])->map(fn ($u) => strtolower(ltrim(trim((string) $u), '@')))->filter()->unique()->values()->all();
                if (count($plan[$side]) > $size) {
                    throw new HttpException(422, __('في كل تحالف :n فرق على الأكثر.', ['n' => $size]));
                }
            }
            $all = [...$plan['a'], ...$plan['b']];
            if (count($all) !== count(array_unique($all))) {
                throw new HttpException(422, __('المدرب في تحالف واحد فقط.'));
            }
            $found = User::whereIn('username', $all)->pluck('username')->map(fn ($u) => strtolower($u))->all();
            if ($missing = array_values(array_diff($all, $found))) {
                throw new HttpException(422, __('لا يوجد مدرب باسم المستخدم :name.', ['name' => $missing[0]]));
            }
        }
        $first = DB::table('fixtures')->where('season_id', $league->season->id)->where('competition', 'league')->min('scheduled_at');
        $at = ! empty($data['first_round_at']) ? Carbon::parse($data['first_round_at'])->utc()
            : Carbon::parse($first ?? $league->starts_at, 'UTC')->addDay();
        $now = GameClock::now();

        return DB::table('alliance_tournaments')->insertGetId([
            'league_id' => $league->id, 'season_id' => $league->season->id, 'name' => trim((string) ($data['name'] ?? '')) ?: __('بطولة التحالفات'),
            'status' => 'pending', 'size' => $size, 'captain_a' => $owner->id, 'captain_b' => $owner->id, 'first_round_at' => $at,
            'round_gap_minutes' => $league->is_dev ? (int) config('game.alliance.dev_gap_minutes') : (int) config('game.alliance.gap_minutes'),
            'seed' => random_int(1, 2_147_483_647), 'assign' => $assign, 'plan' => json_encode($plan), 'created_at' => $now, 'updated_at' => $now,
        ]);
    }

    /**
     * [Sprint 40 D1] The teams of a planned tournament, now: the maker's split (each name's club in the league), the places
     * left drawn from the coaches not in it, then from the computer's clubs; or all of it by the draw. Then its first round.
     */
    public static function form(object $t): void
    {
        $plan = json_decode((string) $t->plan, true) ?: ['a' => [], 'b' => []];
        $size = (int) $t->size;
        $clubs = DB::table('clubs')->leftJoin('users', 'users.id', '=', 'clubs.user_id')->where('clubs.league_id', $t->league_id)
            ->orderBy('clubs.id')->get(['clubs.id', 'clubs.user_id', 'users.username']);
        $byName = $clubs->filter(fn ($c) => $c->username)->keyBy(fn ($c) => strtolower($c->username));
        $teams = ['a' => [], 'b' => []];
        foreach (['a', 'b'] as $side) {
            foreach ($plan[$side] ?? [] as $name) {
                if (isset($byName[$name]) && count($teams[$side]) < $size) {
                    $teams[$side][] = (int) $byName[$name]->id;
                }
            }
        }
        $rng = new Randomizer(new Mt19937((int) $t->seed));
        $taken = [...$teams['a'], ...$teams['b']];
        $coached = $rng->shuffleArray($clubs->filter(fn ($c) => $c->user_id && ! in_array((int) $c->id, $taken, true))->pluck('id')->map(fn ($v) => (int) $v)->all());
        $bots = $rng->shuffleArray($clubs->filter(fn ($c) => ! $c->user_id && ! in_array((int) $c->id, $taken, true))->pluck('id')->map(fn ($v) => (int) $v)->all());
        $pool = [...$coached, ...$bots];
        // The places left, in turn: the alliance with fewer takes the next.
        while ((count($teams['a']) < $size || count($teams['b']) < $size) && $pool) {
            $side = count($teams['a']) <= count($teams['b']) && count($teams['a']) < $size ? 'a' : 'b';
            $teams[$side][] = array_shift($pool);
        }
        DB::transaction(function () use ($t, $teams) {
            if (DB::table('alliance_tournaments')->where('id', $t->id)->whereNull('formed_at')->update(['formed_at' => GameClock::now(), 'updated_at' => GameClock::now()]) !== 1) {
                return;
            }
            foreach ($teams as $alliance => $ids) {
                foreach ($ids as $club) {
                    DB::table('alliance_members')->insert(['tournament_id' => $t->id, 'club_id' => $club, 'alliance' => $alliance]);
                }
            }
            $at = Carbon::parse($t->first_round_at, 'UTC');
            $at = $at->lt(GameClock::now()->addMinutes(10)) ? GameClock::now()->addMinutes(10) : $at;
            self::drawRound(DB::table('alliance_tournaments')->where('id', $t->id)->first(), 1, DB::table('alliance_members')->where('tournament_id', $t->id)->pluck('alliance', 'club_id')->all(), $at);
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
                // [Sprint 40 D1] A planned one is formed before its first round (tick()), or now if that time has come.
                if (! $t->formed_at) {
                    if (Carbon::parse($t->first_round_at, 'UTC')->lte($now->copy()->addMinutes((int) config('game.alliance.form_minutes')))) {
                        self::form($t);
                    }

                    return;
                }
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

    /**
     * [Sprint 40 D2] Two coaches of one alliance drawn together: each picks who goes on (himself or the other); the same
     * pick from both decides it. Not agreed by the round's time: the stronger club (tick()).
     */
    public static function decide(int $tieId, User $user, int $winner): void
    {
        $tie = DB::table('alliance_ties')->where('id', $tieId)->first();
        if (! $tie || $tie->kind !== 'captain' || $tie->winner_id) {
            throw new HttpException(409, __('هذه المواجهة ليست بانتظار اتفاق المدربين.'));
        }
        if (! in_array($winner, [(int) $tie->home_id, (int) $tie->away_id], true)) {
            throw new HttpException(422, 'اختر أحد المدربين في هذه المواجهة.');
        }
        $coaches = DB::table('clubs')->whereIn('id', [$tie->home_id, $tie->away_id])->pluck('user_id', 'id');
        $side = (int) ($coaches[$tie->home_id] ?? 0) === $user->id ? 'home_pick' : ((int) ($coaches[$tie->away_id] ?? 0) === $user->id ? 'away_pick' : null);
        if (! $side) {
            throw new HttpException(403, __('القرار لمدربي الفريقين.'));
        }
        DB::table('alliance_ties')->where('id', $tieId)->whereNull('winner_id')->update([$side => $winner, 'updated_at' => GameClock::now()]);
        $tie = DB::table('alliance_ties')->where('id', $tieId)->first();
        // The other team's coach is the computer: his pick is the coach's.
        $other = $side === 'home_pick' ? 'away' : 'home';
        $agreed = $tie->home_pick && $tie->away_pick && (int) $tie->home_pick === (int) $tie->away_pick;
        if ($agreed || ! $coaches[$tie->{$other.'_id'}]) {
            DB::table('alliance_ties')->where('id', $tieId)->whereNull('winner_id')->update(['winner_id' => $winner, 'updated_at' => GameClock::now()]);
            self::advance((int) $tie->tournament_id);
        }
    }

    /**
     * [Sprint 40 D2] The reward of the one who goes on: up to swap_max players swapped one for one with the team he
     * passed, his choice (a final of team-mates ends the tournament, and its reward stands). Players on loan stay.
     *
     * @param  list<int>  $give  his players
     * @param  list<int>  $take  the other team's
     */
    public static function swap(int $tieId, User $user, array $give, array $take): int
    {
        return DB::transaction(function () use ($tieId, $user, $give, $take) {
            $tie = DB::table('alliance_ties')->where('id', $tieId)->first();
            if (! $tie || $tie->kind !== 'captain' || ! $tie->winner_id) {
                throw new HttpException(409, __('التبادل لمن أكمل بعد اتفاق المدربين.'));
            }
            $mine = (int) $tie->winner_id;
            $theirs = $mine === (int) $tie->home_id ? (int) $tie->away_id : (int) $tie->home_id;
            if ((int) DB::table('clubs')->where('id', $mine)->value('user_id') !== $user->id) {
                throw new HttpException(403, __('التبادل لمدرب الفريق الذي أكمل.'));
            }
            $give = array_values(array_unique(array_map('intval', $give)));
            $take = array_values(array_unique(array_map('intval', $take)));
            $left = (int) config('game.alliance.swap_max') - (int) $tie->swaps;
            if (! $give || count($give) !== count($take) || count($give) > $left) {
                throw new HttpException(422, __('لاعب مقابل لاعب، حتى :n.', ['n' => max(0, $left)]));
            }
            $loaned = DB::table('player_loans')->whereIn('player_id', [...$give, ...$take])->where('status', 'active')->exists();
            if ($loaned || DB::table('players')->whereIn('id', $give)->where('club_id', $mine)->count() !== count($give)
                || DB::table('players')->whereIn('id', $take)->where('club_id', $theirs)->count() !== count($take)) {
                throw new HttpException(422, __('بعض اللاعبين ليسوا في الفريقين أو معارون.'));
            }
            $now = GameClock::now();
            $season = (int) DB::table('alliance_tournaments')->where('id', $tie->tournament_id)->value('season_id');
            foreach ([[$give, $mine, $theirs], [$take, $theirs, $mine]] as [$players, $was, $goes]) {
                foreach ($players as $p) {
                    DB::table('players')->where('id', $p)->where('club_id', $was)->update(['club_id' => $goes, 'updated_at' => $now]);
                    DB::table('player_moves')->insert(['season_id' => $season, 'player_id' => $p, 'from_club_id' => $was, 'to_club_id' => $goes, 'price' => 0, 'created_at' => $now]);
                    Transfers::left($p, $was);
                }
            }
            DB::table('alliance_ties')->where('id', $tieId)->increment('swaps', count($give));

            return count($give);
        });
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
        // [Sprint 40 D1] The planned ones whose first round is near: their teams now.
        $due = DB::table('alliance_tournaments')->where('status', 'running')->whereNull('formed_at')
            ->where('first_round_at', '<=', GameClock::now()->addMinutes((int) config('game.alliance.form_minutes')))->get();
        foreach ($due as $t) {
            self::form($t);
            $n++;
        }
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
