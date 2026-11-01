<?php

namespace App\Http\Controllers\Api;

use App\Auth\Username;
use App\Http\Controllers\Controller;
use App\Ideas\Polls;
use App\League\ClubAgenda;
use App\League\CoachSlots;
use App\League\Standings;
use App\Messages\Inbox;
use App\Models\Club;
use App\Models\League;
use App\Models\User;
use App\Season\Achievements;
use App\Season\Career;
use App\Season\CoachRating;
use App\Season\Onboarding;
use App\Wallet\StarterGift;
use App\Wallet\Wallet;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * The coach's home screen [X18]: the profile card with the level, the club slots (a team in each of up to eight
 * leagues, opening with the account's age), the trophies, the coaches met, and the developers' latest announcements. And the global ranking.
 */
class HomeController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();
        $record = Career::record($user->id);
        $trophies = Career::trophies($user->id);

        return response()->json([
            'coach' => ['id' => $user->id, 'name' => $user->name, 'username' => $user->username, 'avatar_url' => $user->avatarUrl(),
                'account_no' => $user->account_no, 'official' => Username::official($user->username), 'verified' => $user->account_verified_at !== null, 'level' => Career::level($record, $trophies), 'record' => $record,
                'coins' => Wallet::balance($user->id), 'rating' => CoachRating::of($user->id)],
            // [Sprint 25] The rating's tiers, for the ladder.
            'rating_tiers' => CoachRating::ladder(),
            // [Sprint 24 B3] The slots open now, of all of them, and when the next one opens.
            'slots_open' => CoachSlots::open($user), 'next_slot_at' => CoachSlots::next($user)?->toIso8601ZuluString(),
            'trophies' => $trophies,
            'slots' => $this->slots($user),
            'colleagues' => $this->colleagues($user->id),
            'announcements' => DB::table('messages')->where('user_id', $user->id)->where('type', 'announcement')->orderByDesc('id')->limit(5)->get()
                ->map(fn ($m) => Inbox::view($m))->values(),
            // [Sprint 28] The open polls this coach has not voted in yet.
            'polls_waiting' => Polls::waiting($user->id),
            // [Sprint 30 P6] The new coach's first coins, to claim from here once.
            'starter_gift' => StarterGift::view($user),
            // [X75] The first steps, each done in the game (never by tapping it).
            'onboarding' => Onboarding::of($user),
        ]);
    }

    /** [Sprint 30 G4] The coach's achievements, or another coach's (they are public like the ranking). */
    public function achievements(Request $request): JsonResponse
    {
        $id = (int) ($request->validate(['user' => ['sometimes', 'integer', 'exists:users,id']])['user'] ?? $request->user()->id);

        return response()->json(['achievements' => Achievements::of($id)]);
    }

    /** [Sprint 30 P6] «استلم مكافأتك»: the starter coins, once per account. */
    public function claimStarter(Request $request): JsonResponse
    {
        $balance = StarterGift::claim($request->user());

        return response()->json(['coins' => $balance, 'starter_gift' => StarterGift::view($request->user())]);
    }

    /**
     * The slots (game.league.max_active_teams, 8): a club in a league, a request waiting for its answer, free, or
     * locked until the account is old enough [Sprint 24 B3] (opens_at, for the countdown). A team held from before
     * the slots opened with age keeps its slot, so a coach may show more teams than open slots, never fewer.
     */
    private function slots(User $user): array
    {
        $max = (int) config('game.league.max_active_teams');
        $open = CoachSlots::open($user);
        $created = Carbon::parse($user->created_at, 'UTC');
        $out = [];
        $memberships = DB::table('league_memberships')->join('leagues', 'leagues.id', '=', 'league_memberships.league_id')
            ->leftJoin('clubs', 'clubs.id', '=', 'league_memberships.club_id')
            ->where('league_memberships.user_id', $user->id)->whereNull('league_memberships.left_at')->whereNotNull('league_memberships.club_id')
            ->orderBy('league_memberships.joined_at')
            ->get(['leagues.id as league_id', 'leagues.name as league', 'leagues.status', 'league_memberships.season_id', 'clubs.id as club_id', 'clubs.name as club', 'clubs.master_club_id', 'clubs.balance']);
        foreach ($memberships as $m) {
            $order = Standings::order((int) $m->season_id);
            $next = DB::table('fixtures')->whereIn('status', ['scheduled', 'locked', 'live'])->where('is_bye', false)
                ->where(fn ($q) => $q->where('home_id', $m->club_id)->orWhere('away_id', $m->club_id))->whereNotNull('home_id')->whereNotNull('away_id')
                ->orderBy('scheduled_at')->first();
            $opponent = $next ? DB::table('clubs')->where('id', $next->home_id === $m->club_id ? $next->away_id : $next->home_id)->value('name') : null;
            // [Sprint 20 B2] What waits for the coach in this club, as the club board counts it.
            $club = Club::find($m->club_id);
            $pending = count(ClubAgenda::pending($club, League::find($m->league_id), $user->id));
            $out[] = ['state' => 'club', 'league' => ['id' => (int) $m->league_id, 'name' => $m->league, 'status' => $m->status], 'pending' => $pending,
                'club' => ['id' => (int) $m->club_id, 'name' => $m->club, 'crest_url' => url("/api/v1/data/clubs/{$m->master_club_id}/crest.svg"), 'cash' => (int) $m->balance],
                'position' => ($i = array_search((int) $m->club_id, $order, true)) === false ? null : $i + 1, 'teams' => count($order),
                'next_match' => $next ? ['opponent' => $opponent, 'venue' => $next->home_id === $m->club_id ? 'home' : 'away', 'live' => $next->status === 'live',
                    'scheduled_at' => Carbon::parse($next->scheduled_at, 'UTC')->toIso8601ZuluString()] : null];
        }
        foreach (DB::table('league_join_requests')->join('leagues', 'leagues.id', '=', 'league_join_requests.league_id')
            ->where('league_join_requests.user_id', $user->id)->where('league_join_requests.status', 'pending')->limit($max)->get(['leagues.id', 'leagues.name']) as $r) {
            if (count($out) < max($max, count($memberships))) {
                $out[] = ['state' => 'waiting', 'league' => ['id' => (int) $r->id, 'name' => $r->name, 'status' => 'waiting'], 'pending' => 0, 'club' => null, 'position' => null, 'teams' => null, 'next_match' => null];
            }
        }
        while (count($out) < $open) {
            $out[] = ['state' => 'free', 'league' => null, 'pending' => 0, 'club' => null, 'position' => null, 'teams' => null, 'next_match' => null];
        }
        $first = true;
        while (count($out) < $max) {
            $n = count($out) + 1;
            // Only the first locked slot is bought (with any before it): they open in order.
            $out[] = ['state' => 'locked', 'league' => null, 'pending' => 0, 'club' => null, 'position' => null, 'teams' => null, 'next_match' => null,
                'opens_at' => CoachSlots::opensAt($created, $n)->toIso8601ZuluString(), 'progress_bp' => CoachSlots::progressBp($user, $n),
                'unlock_coins' => $first ? CoachSlots::price($user, $n) : null];
            $first = false;
        }

        return array_map(fn ($s, $i) => ['slot' => $i + 1] + $s + ['opens_at' => null, 'progress_bp' => null, 'unlock_coins' => null], $out, array_keys($out));
    }

    /** [Sprint 24 B3] Open a locked slot now for its coins (and any locked before it), then the home screen again. */
    public function unlock(Request $request, int $slot): JsonResponse
    {
        CoachSlots::unlock($request->user(), $slot);

        return $this->show($request);
    }

    /** The other coaches in the coach's leagues (any season). */
    private function colleagues(int $userId): int
    {
        $leagues = DB::table('league_memberships')->where('user_id', $userId)->pluck('league_id');

        return DB::table('league_memberships')->whereIn('league_id', $leagues)->whereNotNull('user_id')->where('user_id', '!=', $userId)->distinct()->count('user_id');
    }

    /**
     * The coaches' global ranking [X18]: by trophies (then league titles, then wins), by level, or by the rating's
     * points [Sprint 25] (then trophies). Top 50 and the coach's own place.
     */
    public function ranking(Request $request): JsonResponse
    {
        $by = $request->validate(['by' => ['sometimes', 'in:trophies,level,rating']])['by'] ?? 'trophies';
        $ids = DB::table('league_memberships')->whereNotNull('user_id')->whereNotNull('club_id')->distinct()->pluck('user_id')
            ->merge(DB::table('titles')->whereNotNull('user_id')->distinct()->pluck('user_id'))->unique();
        $users = User::whereIn('id', $ids)->get(['id', 'name', 'username']);
        $rows = $users->map(function (User $u) {
            $record = Career::record($u->id);
            $trophies = Career::trophies($u->id);
            $rating = CoachRating::of($u->id);

            return ['coach' => ['id' => $u->id, 'name' => $u->name, 'username' => $u->username, 'avatar_url' => $u->avatarUrl(), 'official' => Username::official($u->username), 'verified' => $u->account_verified_at !== null],
                'trophies' => $trophies, 'won' => $record['won'], 'played' => $record['played'], 'level' => Career::level($record, $trophies)['level'],
                'rating' => ['points' => $rating['points'], 'tier' => $rating['tier']['key'], 'division' => $rating['tier']['division']]];
        })->sortBy(match ($by) {
            'level' => [['level', 'desc'], ['trophies.total', 'desc'], ['won', 'desc']],
            'rating' => [['rating.points', 'desc'], ['trophies.total', 'desc'], ['won', 'desc']],
            default => [['trophies.total', 'desc'], ['trophies.league', 'desc'], ['won', 'desc']],
        })->values()
            ->map(fn ($r, $i) => ['position' => $i + 1] + $r);
        $mine = $rows->firstWhere('coach.id', $request->user()->id);

        return response()->json(['by' => $by, 'coaches' => $rows->take(50)->values(), 'me' => $mine]);
    }
}
