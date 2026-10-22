<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\League\Joining;
use App\League\LeagueFactory;
use App\League\LeagueStarter;
use App\Models\Club;
use App\Models\League;
use App\Models\LeagueJoinRequest;
use App\Models\LeagueMembership;
use App\Models\User;
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
            'coaches' => Club::where('league_id', $l->id)->whereNotNull('user_id')->count(),
            'season' => $season ? [
                'number' => $season->number, 'status' => $season->status, 'rounds' => $season->rounds,
                'rounds_played' => $season->rounds_played, 'lock_from_round' => $season->lock_from_round,
                'join_open' => $l->status !== 'finished' && ! $season->inLastQuarter(),
            ] : null,
        ];
    }

    private function clubData(Club $c): array
    {
        return [
            'id' => $c->id, 'name' => $c->name, 'code' => $c->code, 'colors' => [$c->color_primary, $c->color_secondary],
            'crest_url' => url("/api/v1/data/clubs/{$c->master_club_id}/crest.svg"),
            'strength_cp' => (int) $c->strength_snapshot,
            'coach' => $c->user ? ['id' => $c->user->id, 'name' => $c->user->name] : null,
            'bot' => $c->isBot(),
            'balance' => (int) $c->balance,
            'squad_value' => (int) $c->squad_value,
            'players_count' => (int) $c->players_count,
        ];
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
