<?php

namespace App\Http\Controllers\Api;

use App\Auth\Username;
use App\Http\Controllers\Controller;
use App\League\CupBracket;
use App\League\Joining;
use App\League\LeagueFactory;
use App\League\LeagueStarter;
use App\League\Leaving;
use App\League\Presence;
use App\League\SeasonScheduler;
use App\Models\Club;
use App\Models\League;
use App\Models\LeagueJoinRequest;
use App\Models\LeagueMembership;
use App\Models\User;
use App\Season\Objectives;
use App\Support\GameClock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

/**
 * Private leagues and the way in [PLAN 2.1, 2.3]: make a league, ask to join by its code, the owner
 * approves, and the coach takes a club no one has. Every rule lives in App\League.
 */
class LeagueController extends Controller
{
    /** My leagues: the ones I run, coach in, or asked to join. */
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $ids = League::where('owner_id', $user->id)->pluck('id')
            ->merge(LeagueMembership::where('user_id', $user->id)->whereNull('left_at')->pluck('league_id'))
            ->merge(LeagueJoinRequest::where('user_id', $user->id)->where('status', '!=', 'rejected')->pluck('league_id'))
            ->unique();
        $leagues = League::whereIn('id', $ids)->with('season', 'owner')->orderByDesc('id')->get();

        return response()->json([
            'leagues' => $leagues->map(fn (League $l) => $this->leagueData($l, $user)),
            'active_teams' => Joining::activeTeams($user),
            'max_active_teams' => config('game.league.max_active_teams'),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $this->settings($request, true);
        $league = LeagueFactory::create($request->user(), $data);

        return response()->json(['league' => $this->leagueData($league->load('season', 'owner'), $request->user())], 201);
    }

    public function show(Request $request, League $league): JsonResponse
    {
        $this->visible($request->user(), $league);

        return response()->json(['league' => $this->leagueData($league->load('season', 'owner'), $request->user())]);
    }

    /** The owner changes settings until the league starts; then all of them are locked [PLAN 2.3]. */
    public function update(Request $request, League $league): JsonResponse
    {
        $this->owner($request->user(), $league);
        abort_if($league->isLocked(), 409, 'إعدادات الدوري مقفلة منذ بدايته.');
        $data = $this->settings($request, false);
        if (array_key_exists('name', $data)) {
            $name = trim((string) $data['name']);
            $data['name'] = $name !== '' ? $name : $league->template.' #'.$league->code;
        }
        DB::transaction(function () use ($league, $data) {
            // Conditional on still waiting: a start in the same moment wins and the change is refused.
            $changed = DB::table('leagues')->where('id', $league->id)->whereNull('settings_locked_at')
                ->update(collect($data)->map(fn ($v) => is_array($v) ? json_encode(array_values($v)) : $v)->all() + ['updated_at' => GameClock::now()]);
            abort_if($changed !== 1, 409, 'إعدادات الدوري مقفلة منذ بدايته.');
            if (isset($data['starts_at'])) {
                DB::table('seasons')->where('league_id', $league->id)->where('number', 1)->update(['starts_at' => $data['starts_at']]);
            }
            // New times make the calendar again (nothing has been played before the start).
            if (array_intersect_key($data, array_flip(['starts_at', 'prep_days', 'rounds_per_day', 'round_times']))) {
                $fresh = $league->fresh();
                SeasonScheduler::build($fresh, $fresh->season);
            }
        });

        return response()->json(['league' => $this->leagueData($league->fresh()->load('season', 'owner'), $request->user())]);
    }

    /** "Start now" for the owner, in development only [PLAN 2.1]. */
    public function start(Request $request, League $league): JsonResponse
    {
        abort_if(app()->isProduction(), 404);
        $this->owner($request->user(), $league);
        abort_unless(LeagueStarter::start($league), 409, 'بدأ الدوري من قبل.');

        return response()->json(['league' => $this->leagueData($league->fresh()->load('season', 'owner'), $request->user())]);
    }

    /** Ask to join with the league's 8-letter code. */
    public function join(Request $request): JsonResponse
    {
        $data = $request->validate(['code' => ['required', 'string', 'max:20']]);
        $code = strtoupper(preg_replace('/[\s#-]+/', '', $data['code']));
        $league = League::where('code', $code)->first();
        abort_unless($league, 404, 'لا يوجد دوري بهذا الكود.');
        $joinRequest = Joining::request($request->user(), $league->load('season'));

        return response()->json([
            'request' => $this->requestData($joinRequest),
            'league' => $this->leagueData($league->load('owner'), $request->user()),
        ], $joinRequest->wasRecentlyCreated ? 201 : 200);
    }

    /**
     * Ask for a holiday of 1 to 7 days in this league alone, once a season, with a reason its owner approves [X4].
     * The account's holiday covers every league without asking (PUT /auth/vacation).
     */
    public function vacation(Request $request, League $league): JsonResponse
    {
        $data = $request->validate([
            'days' => ['required', 'integer', 'between:1,'.config('game.league.vacation_max_days')],
            'reason' => ['required', 'string', 'min:5', 'max:300'],
        ]);
        Presence::askHoliday($this->membership($request->user(), $league), (int) $data['days'], trim($data['reason']), $league->isOwner($request->user()));

        return response()->json(['league' => $this->leagueData($league->fresh()->load('season', 'owner'), $request->user())]);
    }

    /** The owner approves a coach's holiday request [X4]. */
    public function approveVacation(Request $request, League $league, LeagueMembership $membership): JsonResponse
    {
        return $this->decideVacation($request, $league, $membership, true);
    }

    public function rejectVacation(Request $request, League $league, LeagueMembership $membership): JsonResponse
    {
        return $this->decideVacation($request, $league, $membership, false);
    }

    private function decideVacation(Request $request, League $league, LeagueMembership $membership, bool $approve): JsonResponse
    {
        $this->owner($request->user(), $league);
        abort_unless($membership->league_id === $league->id, 404);
        Presence::decide($membership, $approve);

        return response()->json(['league' => $this->leagueData($league->fresh()->load('season', 'owner'), $request->user())]);
    }

    public function endVacation(Request $request, League $league): JsonResponse
    {
        Presence::endHoliday($this->membership($request->user(), $league));

        return response()->json(['league' => $this->leagueData($league->fresh()->load('season', 'owner'), $request->user())]);
    }

    /** The coach resigns: the club goes back to a bot [PLAN 2.2, Sprint 32]. */
    public function resign(Request $request, League $league): JsonResponse
    {
        Leaving::resign($this->membership($request->user(), $league));

        return response()->json(['left' => true]);
    }

    /** The owner sends a coach away with a written reason that every member sees [PLAN 2.1]. */
    public function kick(Request $request, League $league, LeagueMembership $membership): JsonResponse
    {
        $this->owner($request->user(), $league);
        abort_unless($membership->league_id === $league->id, 404);
        $data = $request->validate(['reason' => ['required', 'string', 'min:3', 'max:200']]);
        Leaving::kick($membership, trim($data['reason']));

        return response()->json(['league' => $this->leagueData($league->fresh()->load('season', 'owner'), $request->user())]);
    }

    /** Take back my request while it waits. */
    public function cancel(Request $request, League $league): JsonResponse
    {
        $gone = LeagueJoinRequest::where('league_id', $league->id)->where('user_id', $request->user()->id)->where('status', 'pending')->delete();
        abort_unless($gone === 1, 404, 'لا يوجد طلب معلق لك في هذا الدوري.');

        return response()->json(['cancelled' => true]);
    }

    public function requests(Request $request, League $league): JsonResponse
    {
        $this->owner($request->user(), $league);
        $requests = $league->requests()->with('user')->orderByRaw("case status when 'pending' then 0 else 1 end")->orderBy('id')->get();

        return response()->json(['requests' => $requests->map(fn ($r) => $this->requestData($r))]);
    }

    public function approve(Request $request, League $league, LeagueJoinRequest $joinRequest): JsonResponse
    {
        return $this->decide($request, $league, $joinRequest, true);
    }

    public function reject(Request $request, League $league, LeagueJoinRequest $joinRequest): JsonResponse
    {
        return $this->decide($request, $league, $joinRequest, false);
    }

    /** Every club with what a coach needs to choose: coach or bot, strength, money, squad value [PLAN 2.1]. */
    public function clubs(Request $request, League $league): JsonResponse
    {
        $this->approvedOnly($request->user(), $league);
        $clubs = $league->clubs()->with('user')->withSum('players as squad_value', 'value')->withCount('players')
            ->orderByDesc('strength_snapshot')->orderBy('id')->get();

        return response()->json(['clubs' => $clubs->map(fn (Club $c) => $this->clubData($c))]);
    }

    public function club(Request $request, League $league, Club $club): JsonResponse
    {
        $this->approvedOnly($request->user(), $league);
        abort_unless($club->league_id === $league->id, 404);
        $club->load('user')->loadSum('players as squad_value', 'value')->loadCount('players');
        $players = $club->players()->with('master')->get()
            ->sortBy(fn ($p) => [['gk' => 0, 'def' => 1, 'mid' => 2, 'att' => 3][$p->master->line] ?? 4, -$p->overall])->values();

        return response()->json($this->clubData($club) + [
            'players' => $players->map(fn ($p) => [
                'id' => $p->id, 'name' => $p->master->name, 'position' => $p->master->position, 'line' => $p->master->line,
                'age' => $p->master->age, 'nationality' => $p->master->nationality,
                'overall' => $p->overall, 'potential' => $p->master->potential, 'value' => (int) $p->value,
                'fitness' => $p->fitness, 'injured_matches' => $p->injured_matches, 'suspended_matches' => $p->suspended_matches,
            ]),
        ]);
    }

    /** The season's calendar: every league round and cup day with its time (UTC; screens show the device's time) [PLAN 2.4]. */
    public function fixtures(Request $request, League $league): JsonResponse
    {
        $this->approvedOnly($request->user(), $league);
        $this->ensureCalendar($league);
        $season = $league->season;
        $clubs = $this->clubCards($league);
        $stages = CupBracket::stages($league->team_count);
        $rows = DB::table('fixtures')->where('season_id', $season->id)->orderBy('scheduled_at')->orderBy('competition')->orderBy('id')->get();

        return response()->json([
            'season' => $this->seasonData($league),
            'fixtures' => $rows->map(fn ($f) => [
                'id' => $f->id, 'competition' => $f->competition, 'round' => $f->round,
                'stage' => $f->competition === 'cup' ? $stages[$f->round - 1] : null,
                'scheduled_at' => Carbon::parse($f->scheduled_at, 'UTC')->toIso8601ZuluString(),
                'home' => $f->home_id ? $clubs[$f->home_id] : null, 'away' => $f->away_id ? $clubs[$f->away_id] : null,
                'is_bye' => (bool) $f->is_bye, 'status' => $f->status, 'home_goals' => $f->home_goals, 'away_goals' => $f->away_goals,
            ])->values(),
        ]);
    }

    /** The league table, with "played" and who rests in the next round when the count is odd [PLAN 2.4]. */
    public function standings(Request $request, League $league): JsonResponse
    {
        $this->approvedOnly($request->user(), $league);
        $this->ensureCalendar($league);
        $season = $league->season;
        $clubs = $this->clubCards($league);
        $rows = collect($clubs)->map(fn ($c) => $c + ['played' => 0, 'won' => 0, 'drawn' => 0, 'lost' => 0, 'goals_for' => 0, 'goals_against' => 0]);
        $done = DB::table('fixtures')->where('season_id', $season->id)->where('competition', 'league')->where('is_bye', false)->where('status', 'finished')->get();
        foreach ($done as $f) {
            foreach ([[$f->home_id, $f->home_goals, $f->away_goals], [$f->away_id, $f->away_goals, $f->home_goals]] as [$id, $for, $against]) {
                $r = $rows[$id];
                $r['played']++;
                $r['goals_for'] += $for;
                $r['goals_against'] += $against;
                $r[$for > $against ? 'won' : ($for === $against ? 'drawn' : 'lost')]++;
                $rows[$id] = $r;
            }
        }
        $next = DB::table('fixtures')->where('season_id', $season->id)->where('competition', 'league')->where('status', 'scheduled')->min('round');
        $resting = $next ? DB::table('fixtures')->where('season_id', $season->id)->where('round', $next)->where('competition', 'league')->where('is_bye', true)->value('home_id') : null;
        $table = $rows->map(fn ($r) => $r + ['goal_difference' => $r['goals_for'] - $r['goals_against'], 'points' => 3 * $r['won'] + $r['drawn'], 'rests_next' => $r['id'] === $resting])
            ->sortBy([['points', 'desc'], ['goal_difference', 'desc'], ['goals_for', 'desc'], ['strength_cp', 'desc']])->values()
            ->map(fn ($r, $i) => ['position' => $i + 1] + $r);

        return response()->json(['season' => $this->seasonData($league), 'next_round' => $next, 'table' => $table]);
    }

    /** The cup's bracket, stage by stage with each stage's day [PLAN 2.5]. */
    public function cup(Request $request, League $league): JsonResponse
    {
        $this->approvedOnly($request->user(), $league);
        $this->ensureCalendar($league);
        $season = $league->season;
        $clubs = $this->clubCards($league);
        $ties = DB::table('cup_ties')->join('fixtures', 'fixtures.id', '=', 'cup_ties.fixture_id')->where('cup_ties.season_id', $season->id)
            ->select('cup_ties.*', 'fixtures.scheduled_at', 'fixtures.status', 'fixtures.home_goals', 'fixtures.away_goals')->orderBy('cup_ties.slot')->get()->groupBy('stage');
        $ids = DB::table('cup_ties')->where('season_id', $season->id)->pluck('slot', 'id');

        return response()->json(['stages' => collect(CupBracket::stages($league->team_count))->map(fn ($stage) => [
            'stage' => $stage,
            'scheduled_at' => Carbon::parse($ties[$stage][0]->scheduled_at, 'UTC')->toIso8601ZuluString(),
            'ties' => $ties[$stage]->map(fn ($t) => [
                'id' => $t->id, 'slot' => $t->slot,
                'home' => $t->home_id ? $clubs[$t->home_id] : null, 'away' => $t->away_id ? $clubs[$t->away_id] : null,
                'winner_id' => $t->winner_id, 'status' => $t->status, 'home_goals' => $t->home_goals, 'away_goals' => $t->away_goals,
                'next' => $t->next_tie_id ? ['slot' => $ids[$t->next_tie_id], 'side' => $t->next_side] : null,
            ])->values(),
        ])]);
    }

    /** Take a club no coach has. 409 "taken" sends the coach back to the list. */
    public function claim(Request $request, League $league, Club $club): JsonResponse
    {
        abort_unless($club->league_id === $league->id, 404);
        $membership = Joining::claim($request->user(), $league, $club->id);
        $club->refresh()->load('user')->loadSum('players as squad_value', 'value')->loadCount('players');

        return response()->json(['club' => $this->clubData($club), 'joined_at' => $membership->joined_at->toIso8601ZuluString()], 201);
    }

    private function decide(Request $request, League $league, LeagueJoinRequest $joinRequest, bool $approve): JsonResponse
    {
        $this->owner($request->user(), $league);
        abort_unless($joinRequest->league_id === $league->id, 404);

        return response()->json(['request' => $this->requestData(Joining::decide($joinRequest, $approve)->load('user'))]);
    }

    /** The settings of a new league, or the ones changed before it starts (team count, template and budget are fixed). */
    private function settings(Request $request, bool $creating): array
    {
        $c = config('game.league');
        $e = config('game.economy');
        $sometimes = $creating ? 'required' : 'sometimes';
        $rules = [
            'name' => ['nullable', 'string', 'max:60'],
            'rounds_per_day' => [$sometimes, 'integer', 'between:'.$c['rounds_per_day'][0].','.$c['rounds_per_day'][1]],
            'round_times' => [$sometimes, 'array', 'size:'.(int) $request->input('rounds_per_day', 1)],
            'round_times.*' => ['date_format:H:i', 'distinct'],
            'prep_days' => [$sometimes, 'integer', 'between:'.$c['prep_days'][0].','.$c['prep_days'][1]],
            'season_end_mode' => [$sometimes, Rule::in(League::END_MODES)],
            'starts_at' => [$sometimes, 'date'],
            'fair_league' => ['sometimes', 'boolean'],
        ];
        if ($creating) {
            $rules += [
                'template' => ['required', 'string', 'max:80'],
                'team_count' => ['required', 'integer', 'between:'.$c['min_teams'].','.$c['max_teams']],
                'starting_budget' => ['sometimes', 'integer', 'between:'.$e['starting_budget_min'].','.$e['starting_budget_max']],
                'is_dev' => ['sometimes', 'boolean'],
                'club_id' => ['required', 'integer'],
            ];
        } elseif ($request->has('rounds_per_day') xor $request->has('round_times')) {
            throw ValidationException::withMessages(['round_times' => 'أرسل الجولات يومياً ومواعيدها معاً.']);
        }
        $data = $request->validate($rules);
        if (isset($data['starts_at'])) {
            $at = Carbon::parse($data['starts_at'])->utc()->startOfMinute();
            $now = GameClock::now();
            // A minute's slack for "now" sent from a slow phone.
            if ($at->lt($now->copy()->subMinute()) || $at->gt($now->copy()->addDays($c['starts_within_days']))) {
                throw ValidationException::withMessages(['starts_at' => 'اختر موعد البدء من الآن حتى '.$c['starts_within_days'].' أيام.']);
            }
            $data['starts_at'] = $at->max($now->copy()->startOfMinute());
        }
        if ($creating) {
            $data['master_club_id'] = (int) $data['club_id'];
            unset($data['club_id']);
            $data['starting_budget'] ??= $e['starting_budget'];
            $data['fair_league'] = (bool) ($data['fair_league'] ?? false);
            $data['is_dev'] = ! app()->isProduction() && ($data['is_dev'] ?? false);
        }

        return $data;
    }

    /** Leagues made before the calendar existed (Sprint 15) get theirs the first time it is asked for. */
    private function ensureCalendar(League $league): void
    {
        if (! DB::table('fixtures')->where('season_id', $league->season->id)->exists()) {
            SeasonScheduler::build($league, $league->season);
            $league->refresh();
        }
    }

    /** Every club of the league as the calendar and table show it, by id. */
    private function clubCards(League $league): array
    {
        return Club::where('league_id', $league->id)->with('user')->get()->mapWithKeys(fn (Club $c) => [$c->id => [
            'id' => $c->id, 'name' => $c->name, 'code' => $c->code, 'strength_cp' => (int) $c->strength_snapshot,
            'crest_url' => url("/api/v1/data/clubs/{$c->master_club_id}/crest.svg"), 'coach' => $c->user?->name,
        ]])->all();
    }

    private function seasonData(League $league): array
    {
        $s = $league->season;
        $windows = DB::table('transfer_windows')->where('season_id', $s->id)->get()->map(fn ($w) => [
            'kind' => $w->kind, 'opens_at' => Carbon::parse($w->opens_at, 'UTC')->toIso8601ZuluString(), 'closes_at' => Carbon::parse($w->closes_at, 'UTC')->toIso8601ZuluString(),
        ]);

        return [
            'number' => $s->number, 'status' => $s->status, 'rounds' => $s->rounds, 'rounds_played' => $s->rounds_played,
            'lock_from_round' => $s->lock_from_round, 'starts_at' => $s->starts_at->toIso8601ZuluString(),
            'ends_at' => $s->ends_at ? Carbon::parse($s->ends_at, 'UTC')->toIso8601ZuluString() : null,
            'winter_break_on' => $s->winter_break_on?->toDateString(), 'windows' => $windows, 'timer_scale' => $league->timer_scale,
        ];
    }

    /** My place in this league's current season. */
    private function membership(User $user, League $league): LeagueMembership
    {
        $m = LeagueMembership::where('league_id', $league->id)->where('season_id', $league->season->id)
            ->where('user_id', $user->id)->whereNull('left_at')->first();
        abort_unless($m, 403, 'ليس لديك فريق في هذا الدوري.');

        return $m;
    }

    private function owner(User $user, League $league): void
    {
        abort_unless($league->isOwner($user), 403, 'هذا لمنشئ الدوري فقط.');
    }

    /** The owner, its coaches, and anyone who asked to join (and was not turned down) see the league. */
    private function visible(User $user, League $league): void
    {
        $asked = LeagueJoinRequest::where('league_id', $league->id)->where('user_id', $user->id)->where('status', '!=', 'rejected')->exists();
        $coach = LeagueMembership::where('league_id', $league->id)->where('user_id', $user->id)->exists();
        abort_unless($league->isOwner($user) || $asked || $coach, 404);
    }

    private function approvedOnly(User $user, League $league): void
    {
        $this->visible($user, $league);
        abort_unless(Joining::approved($user, $league), 403, 'ينتظر طلبك موافقة منشئ الدوري.');
    }

    private function leagueData(League $l, User $user): array
    {
        $approved = Joining::approved($user, $l);
        $season = $l->season;
        $mine = Club::where('league_id', $l->id)->where('user_id', $user->id)->value('id');

        return [
            'id' => $l->id, 'name' => $l->name, 'template' => $l->template,
            // The code is shared by the owner and its coaches; a coach still waiting does not need it.
            'code' => $approved ? $l->code : null,
            'team_count' => $l->team_count, 'rounds_per_day' => $l->rounds_per_day, 'round_times' => $l->round_times,
            'prep_days' => $l->prep_days, 'season_end_mode' => $l->season_end_mode,
            'starts_at' => $l->starts_at->toIso8601ZuluString(), 'starting_budget' => (int) $l->starting_budget,
            'fair_league' => $l->fair_league, 'is_dev' => $l->is_dev, 'status' => $l->status, 'locked' => $l->isLocked(),
            'owner' => $l->owner ? ['id' => $l->owner->id, 'name' => $l->owner->name] : null,
            'is_owner' => $l->isOwner($user),
            'my_club_id' => $mine,
            'my_request' => $l->isOwner($user) ? null : LeagueJoinRequest::where('league_id', $l->id)->where('user_id', $user->id)->value('status'),
            'coaches' => $coaches = Club::where('league_id', $l->id)->whereNotNull('user_id')->count(),
            'free_clubs' => $l->team_count - $coaches,
            'pending_requests' => $l->isOwner($user) ? LeagueJoinRequest::where('league_id', $l->id)->where('status', 'pending')->count() : null,
            'invite_url' => $approved ? url('/join/'.$l->code) : null,
            'me' => $this->presence($l, $user),
            // Coaches this season, and who left and why: every member sees a kick's reason [PLAN 2.1].
            'members' => $approved ? $this->members($l, $season?->id, $l->isOwner($user)) : [],
            'departures' => $approved ? $this->departures($season?->id) : [],
            'season' => $season ? [
                'number' => $season->number, 'status' => $season->status, 'rounds' => $season->rounds,
                'rounds_played' => $season->rounds_played, 'lock_from_round' => $season->lock_from_round,
                'join_open' => $l->status !== 'finished' && ! $season->inLastQuarter(),
            ] : null,
        ];
    }

    private function presence(League $l, User $user): ?array
    {
        $m = $l->season ? LeagueMembership::where('league_id', $l->id)->where('season_id', $l->season->id)->where('user_id', $user->id)->whereNull('left_at')->first() : null;
        if (! $m) {
            return null;
        }

        return [
            'membership_id' => $m->id,
            'on_holiday' => Presence::onHoliday($m),
            'vacation_until' => $m->vacation_until?->toIso8601ZuluString(),
            'vacation_used' => $m->vacation_from !== null,
            'vacation_requested' => $m->vacation_requested_at !== null,
            'account_vacation' => (bool) $user->onVacation(),
            'absence_warning' => $m->absence_warned_at !== null,
            // When the club goes back to a bot if nothing changes: only once the season counts absence.
            'away_deadline' => ($since = Presence::quietSince($m, $l->season->starts_at))
                ? $since->copy()->addDays(config('game.league.absence_days'))->toIso8601ZuluString() : null,
        ];
    }

    private function members(League $l, ?int $seasonId, bool $owner): array
    {
        return LeagueMembership::where('season_id', $seasonId)->whereNull('left_at')->with('user', 'club')->orderBy('joined_at')->get()
            ->map(fn (LeagueMembership $m) => [
                'id' => $m->id,
                'user' => ['id' => $m->user_id, 'name' => $m->user?->name, 'username' => $m->user?->username, 'avatar_url' => $m->user?->avatarUrl(), 'official' => Username::official($m->user?->username)],
                'club' => $m->club ? ['id' => $m->club->id, 'name' => $m->club->name] : null,
                'is_owner' => $m->user_id === $l->owner_id,
                'on_holiday' => Presence::onHoliday($m),
                // A holiday request waiting for the owner, with its reason: only the owner sees it [X4].
                'vacation_request' => $owner && $m->vacation_requested_at
                    ? ['days' => (int) $m->vacation_request_days, 'reason' => $m->vacation_reason, 'at' => $m->vacation_requested_at->toIso8601ZuluString()] : null,
                'joined_at' => $m->joined_at->toIso8601ZuluString(),
                // The owner sees who has been quiet; coaches do not watch each other.
                'last_active_at' => $owner ? $m->last_active_at?->toIso8601ZuluString() : null,
            ])->all();
    }

    private function departures(?int $seasonId): array
    {
        return LeagueMembership::where('season_id', $seasonId)->whereNotNull('left_at')->with('user', 'club')->orderByDesc('left_at')->get()
            ->map(fn (LeagueMembership $m) => [
                'user' => $m->user?->name ?? 'حساب محذوف',
                'club' => $m->club?->name,
                'reason' => $m->left_reason,
                'kick_reason' => $m->kick_reason,
                'left_at' => $m->left_at->toIso8601ZuluString(),
            ])->all();
    }

    private function clubData(Club $c): array
    {
        return [
            'id' => $c->id, 'name' => $c->name, 'code' => $c->code, 'colors' => [$c->color_primary, $c->color_secondary],
            'crest_url' => url("/api/v1/data/clubs/{$c->master_club_id}/crest.svg"),
            'strength_cp' => (int) $c->strength_snapshot,
            'coach' => $c->user ? ['id' => $c->user->id, 'name' => $c->user->name, 'official' => Username::official($c->user->username)] : null,
            'bot' => $c->isBot(),
            'balance' => (int) $c->balance,
            'squad_value' => (int) $c->squad_value,
            'players_count' => (int) $c->players_count,
            // This season's objectives, shown when a coach picks a team [PLAN 2.20, Sprint 33].
            'objectives' => $this->objectives($c),
        ];
    }

    private function objectives(Club $c): ?array
    {
        $season = DB::table('seasons')->where('league_id', $c->league_id)->orderByDesc('number')->value('id');
        if (! $season) {
            return null;
        }
        if (! DB::table('club_objectives')->where('season_id', $season)->exists()) {
            Objectives::set($season);   // a league made before Sprint 33
        }
        $o = DB::table('club_objectives')->where('club_id', $c->id)->where('season_id', $season)->get()->keyBy('competition');

        return isset($o['league'], $o['cup']) ? [
            'league' => ['target' => (int) $o['league']->target, 'kind' => $o['league']->kind],
            'cup' => ['target' => $o['cup']->target],
        ] : null;
    }

    private function requestData(LeagueJoinRequest $r): array
    {
        return [
            'id' => $r->id, 'league_id' => $r->league_id, 'status' => $r->status,
            'user' => $r->relationLoaded('user') && $r->user ? ['id' => $r->user->id, 'name' => $r->user->name] : null,
            'created_at' => $r->created_at?->toIso8601ZuluString(),
            'decided_at' => $r->decided_at?->toIso8601ZuluString(),
        ];
    }
}
