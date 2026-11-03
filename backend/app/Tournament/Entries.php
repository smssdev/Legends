<?php

namespace App\Tournament;

use App\League\Joining;
use App\League\LiveDraw;
use App\Messages\Inbox;
use App\Models\League;
use App\Models\LeagueJoinRequest;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Random\Engine\Mt19937;
use Random\Randomizer;
use Symfony\Component\HttpKernel\Exception\HttpException;

/**
 * [X68] How a tournament's teams find their coaches (leagues.entry_mode):
 *  - pick: each coach asks with the code and takes a team once the organizer approves, as in a league;
 *  - draw: any player enters from the tournament's page until every team has one; the live draw then gives each
 *    entrant a team at random, ball by ball (it starts auto_draw_minutes after the last place is taken, unless the
 *    organizer set its time; at the start it shares out the teams among whoever entered, the rest to the computer);
 *  - assign: the organizer names each team's coach by username.
 * The same seed gives the same teams to the same players, so the replay shows exactly what happened.
 */
class Entries
{
    public static function mode(League $league): string
    {
        return $league->entry_mode ?: 'pick';
    }

    public static function enter(League $league, User $user): void
    {
        self::assertDrawEntry($league);
        Joining::assertCanTakeAnother($user);
        DB::transaction(function () use ($league, $user) {
            $count = DB::table('tournament_entries')->where('league_id', $league->id)->count();
            if ($count >= $league->team_count) {
                throw new HttpException(409, __('اكتمل عدد المشاركين في البطولة.'));
            }
            if (DB::table('tournament_entries')->insertOrIgnore(['league_id' => $league->id, 'user_id' => $user->id, 'created_at' => GameClock::now()]) !== 1) {
                throw new HttpException(409, __('أنت مشارك في هذه البطولة.'));
            }
            if ($count + 1 === (int) $league->team_count) {
                self::full($league->fresh());
            }
        });
    }

    /**
     * [Sprint 40 C1] The draw chosen as the league is made: its maker names the players by username (himself always one
     * of them), each is told, and when they fill every team the draw is set as when the last place is taken. Fewer, and
     * the draw at the start (or the maker's time) gives the teams left to the computer.
     */
    public static function invite(League $league, User $owner, array $usernames): int
    {
        $names = collect($usernames)->map(fn ($u) => strtolower(ltrim(trim((string) $u), '@')))->filter()->unique()
            ->reject(fn ($u) => $u === strtolower((string) $owner->username))->values();
        if ($names->count() + 1 > (int) $league->team_count) {
            throw new HttpException(422, __('عدد اللاعبين أكبر من عدد الفرق.'));
        }
        $users = User::whereIn('username', $names->all())->get()->keyBy(fn ($u) => strtolower($u->username));
        foreach ($names as $n) {
            if (! isset($users[$n])) {
                throw new HttpException(422, __('لا يوجد مدرب باسم المستخدم :name.', ['name' => $n]));
            }
        }
        $now = GameClock::now();
        foreach ([$owner, ...$users->values()->all()] as $u) {
            DB::table('tournament_entries')->insertOrIgnore(['league_id' => $league->id, 'user_id' => $u->id, 'created_at' => $now]);
            if ($u->id !== $owner->id) {
                Inbox::send($u->id, 'draw_entry', ['league' => $league->name, 'by' => $owner->name, 'league_id' => $league->id,
                    'at' => $league->draw_at?->toIso8601ZuluString() ?? $league->starts_at->toIso8601ZuluString()], $league->id);
            }
        }
        $count = DB::table('tournament_entries')->where('league_id', $league->id)->count();
        if ($count === (int) $league->team_count) {
            self::full($league->fresh());
        }

        return $count;
    }

    public static function leave(League $league, User $user, ?int $userId = null): void
    {
        $userId ??= $user->id;
        if ($userId !== $user->id && ! $league->isOwner($user)) {
            throw new HttpException(403, __('هذا لمنظم البطولة.'));
        }
        if ($league->drawn_at) {
            throw new HttpException(409, __('سُحبت القرعة، ولا انسحاب منها.'));
        }
        DB::table('tournament_entries')->where('league_id', $league->id)->where('user_id', $userId)->delete();
    }

    /** The last place is taken: the draw in auto_draw_minutes, unless the organizer set its time. */
    private static function full(League $league): void
    {
        if ($league->draw_at) {
            return;
        }
        $at = GameClock::now()->addMinutes((int) config('game.tournaments.auto_draw_minutes'));
        $latest = Carbon::parse($league->starts_at)->subMinute();
        if ($at->gt($latest)) {
            $at = $latest;
        }
        if ($at->lte(GameClock::now())) {
            LiveDraw::now($league);

            return;
        }
        LiveDraw::schedule($league, $at->toIso8601ZuluString());
        foreach (DB::table('tournament_entries')->where('league_id', $league->id)->pluck('user_id') as $u) {
            Inbox::send((int) $u, 'tournament_full', ['tournament' => $league->name, 'league_id' => $league->id, 'at' => $at->toIso8601ZuluString(), 'kind' => $league->kind ?: 'league'], $league->id);
        }
    }

    /**
     * At the draw (drawn_at set): each entrant, in the order the seed draws them, gets a team the seed draws for him.
     * An entrant who can no longer take a team (his slots are full) is left out and told.
     */
    public static function assign(League $league): void
    {
        if (self::mode($league) !== 'draw') {
            return;
        }
        $entries = DB::table('tournament_entries')->where('league_id', $league->id)->orderBy('id')->get();
        $clubs = DB::table('clubs')->where('league_id', $league->id)->whereNull('user_id')->orderBy('id')->pluck('id')->map(fn ($id) => (int) $id)->all();
        $rng = new Randomizer(new Mt19937(crc32('owners:'.$league->draw_seed)));
        $players = $rng->shuffleArray($entries->all());
        $teams = $rng->shuffleArray($clubs);
        $position = 0;
        foreach ($players as $i => $entry) {
            $club = $teams[$i] ?? null;
            $user = User::find($entry->user_id);
            if (! $club || ! $user) {
                continue;
            }
            try {
                self::give($league, $user, $club);
            } catch (HttpException $e) {
                Inbox::send($user->id, 'official_message', ['body' => __('لم تأخذ فريقاً في قرعة :name: :why', ['name' => $league->name, 'why' => $e->getMessage()]), 'from' => 'GLM', 'username' => 'GLM'], $league->id);

                continue;
            }
            DB::table('tournament_entries')->where('id', $entry->id)->update(['club_id' => $club, 'position' => ++$position]);
        }
    }

    /** The organizer names a team's coach (assign): club id => username; before the start. */
    public static function name(League $league, User $by, array $owners): int
    {
        if (! $league->isOwner($by)) {
            throw new HttpException(403, __('هذا لمنظم البطولة.'));
        }
        if (self::mode($league) !== 'assign') {
            throw new HttpException(409, __('أصحاب الفرق في هذه البطولة لا يحددهم المنظم.'));
        }
        $n = 0;
        foreach ($owners as $clubId => $username) {
            $username = strtolower(ltrim(trim((string) $username), '@'));
            if ($username === '') {
                continue;
            }
            $user = User::where('username', $username)->first() ?? throw new HttpException(422, __('لا يوجد مدرب باسم المستخدم :name.', ['name' => $username]));
            $club = DB::table('clubs')->where('league_id', $league->id)->where('id', (int) $clubId)->first() ?? throw new HttpException(422, __('بعض الفرق المختارة غير موجودة.'));
            if ((int) $club->user_id === $user->id) {
                continue;
            }
            self::give($league, $user, (int) $club->id);
            Inbox::send($user->id, 'tournament_team', ['tournament' => $league->name, 'team' => $club->name, 'by' => $by->name, 'league_id' => $league->id], $league->id, (int) $club->id);
            $n++;
        }

        return $n;
    }

    /** The coach takes the team: approved as the organizer would, then the claim every coach goes through. */
    private static function give(League $league, User $user, int $clubId): void
    {
        if (! $league->isOwner($user)) {
            LeagueJoinRequest::updateOrCreate(['league_id' => $league->id, 'user_id' => $user->id],
                ['status' => 'approved', 'decided_at' => GameClock::now()]);
        }
        Joining::claim($user, $league->fresh(), $clubId);
    }

    /** The balls that gave the teams to their players, in order, for the draw's screen. */
    public static function steps(League $league): array
    {
        if (self::mode($league) !== 'draw' || ! $league->drawn_at) {
            return [];
        }

        return DB::table('tournament_entries')->join('users', 'users.id', '=', 'tournament_entries.user_id')->where('league_id', $league->id)
            ->whereNotNull('position')->orderBy('position')->get(['tournament_entries.club_id', 'users.id as user_id', 'users.name'])
            ->map(fn ($e) => ['type' => 'owner', 'club' => (int) $e->club_id, 'user' => ['id' => (int) $e->user_id, 'name' => $e->name]])->all();
    }

    /** Who entered so far, for the tournament's page. */
    public static function list(League $league): array
    {
        return DB::table('tournament_entries')->join('users', 'users.id', '=', 'tournament_entries.user_id')->where('league_id', $league->id)
            ->orderBy('tournament_entries.id')->get(['users.id', 'users.name', 'users.username', 'tournament_entries.club_id'])
            ->map(fn ($e) => ['id' => (int) $e->id, 'name' => $e->name, 'username' => $e->username, 'club_id' => $e->club_id ? (int) $e->club_id : null])->all();
    }

    public static function isEntrant(int $leagueId, int $userId): bool
    {
        return DB::table('tournament_entries')->where('league_id', $leagueId)->where('user_id', $userId)->exists();
    }

    private static function assertDrawEntry(League $league): void
    {
        if ($league->kind !== 'tournament' || self::mode($league) !== 'draw') {
            throw new HttpException(409, __('المشاركة في هذه البطولة بطلب فريق من منظمها.'));
        }
        if ($league->drawn_at || $league->status !== 'waiting') {
            throw new HttpException(409, __('سُحبت القرعة، وأُغلقت المشاركة.'));
        }
    }
}
