<?php

namespace App\Http\Controllers\Api;

use App\Economy\Economy;
use App\Economy\Money;
use App\Http\Controllers\Controller;
use App\League\ClubLedger;
use App\League\FormationBook;
use App\League\MatchPrep;
use App\League\Tactics;
use App\League\TeamSheet;
use App\Models\Club;
use App\Models\League;
use App\Models\User;
use App\Stadium\Stadium;
use App\Training\Camp;
use App\Training\Training;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/**
 * My club in a league [PLAN 2.15, 2.16]: the squad with each player's card, the lineup and its editor's
 * choices (the 24 formations and up to 3 of my own), and the captain and set-piece takers.
 */
class TeamController extends Controller
{
    /** The 24 formations, the same for everyone. */
    public function formations(): JsonResponse
    {
        return response()->json([
            'formations' => collect(FormationBook::names())->map(fn ($n) => $this->formation($n, FormationBook::label($n), FormationBook::slots($n))),
            'limits' => FormationBook::LIMITS,
            'grid' => ['rows' => array_keys(FormationBook::ROWS), 'columns' => array_keys(FormationBook::COLUMNS)],
            // Where a player may be dragged [X5]: his line's depth band, and across from touchline to touchline.
            'bands' => FormationBook::BANDS,
            'across' => FormationBook::ACROSS,
        ]);
    }

    public function show(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request->user(), $league);
        $lineup = TeamSheet::current($club);
        $starters = array_flip(array_filter($lineup['starters']));
        $bench = array_flip($lineup['bench']);
        $players = $this->players($club)->map(fn ($p) => $p + ['role' => isset($starters[$p['id']]) ? 'starter' : (isset($bench[$p['id']]) ? 'bench' : 'reserve')]);

        return response()->json([
            'club' => ['id' => $club->id, 'name' => $club->name, 'code' => $club->code, 'strength_cp' => (int) $club->strength_snapshot,
                'balance' => (int) $club->balance, 'crest_url' => url("/api/v1/data/clubs/{$club->master_club_id}/crest.svg")],
            'squad_value' => (int) $players->sum('value'),
            'lines' => $this->lineStrength($players),
            'players' => $players->values(),
            'lineup' => $this->lineup($lineup),
            'takers' => TeamSheet::takers($club, $lineup),
            'custom_formations' => collect(TeamSheet::customs($club))->map(fn ($c) => $this->formation('custom:'.$c['number'], $c['name'], FormationBook::custom($c['cells'])) + ['number' => $c['number'], 'cells' => $c['cells']]),
        ]);
    }

    /** "تحسين": the best lineup now, not saved, for the editor to show before "حفظ". */
    public function suggestion(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request->user(), $league);

        return response()->json(['lineup' => $this->lineup(TeamSheet::best($club) + ['auto' => true])]);
    }

    public function saveLineup(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request->user(), $league);
        $data = $request->validate([
            'formation' => ['required', 'string', 'max:16'],
            'starters' => ['required', 'array'],
            'starters.*' => ['nullable', 'integer'],
            'bench' => ['present', 'array'],
            'bench.*' => ['integer'],
            'positions' => ['sometimes', 'nullable', 'array', 'size:10'],
            'positions.*' => ['array', 'size:2'],
            'positions.*.*' => ['integer'],
        ]);
        TeamSheet::save($club, $data['formation'], array_map(fn ($v) => $v === null ? null : (int) $v, $data['starters']), array_map('intval', $data['bench']),
            $data['positions'] ?? null);

        return $this->show($request, $league);
    }

    /** Go back to the automatic lineup ("تحسين" kept up to date for me). */
    public function resetLineup(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request->user(), $league);
        MatchPrep::assertOpen($club);
        DB::table('lineups')->where('club_id', $club->id)->delete();

        return $this->show($request, $league);
    }

    public function saveFormation(Request $request, League $league, int $number): JsonResponse
    {
        $club = $this->club($request->user(), $league);
        $data = $request->validate([
            'name' => ['required', 'string', 'max:30'],
            'cells' => ['required', 'array'],
            'cells.*' => ['array', 'size:2'],
            'cells.*.0' => ['required', Rule::in(array_keys(FormationBook::ROWS))],
            'cells.*.1' => ['required', 'integer', 'between:1,5'],
        ]);
        TeamSheet::saveCustom($club, $number, trim($data['name']), array_map(fn ($c) => [$c[0], (int) $c[1]], $data['cells']));

        return $this->show($request, $league);
    }

    public function saveTakers(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request->user(), $league);
        $data = $request->validate(collect(['captain', 'penalty', 'free_kick', 'corner'])->mapWithKeys(fn ($r) => [$r => ['nullable', 'integer']])->all());
        TeamSheet::saveTakers($club, $data);

        return $this->show($request, $league);
    }

    /** My tactics, with tips for the next referee when he is known [PLAN 2.14]. */
    public function tactics(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request->user(), $league);
        $t = Tactics::of($club);
        $next = $this->nextFixture($club);

        return response()->json(['tactics' => $t, 'tips' => Tactics::tips($t, $next?->referee_strictness), 'referee' => $next?->referee_strictness,
            'help' => Tactics::HELP]);
    }

    public function saveTactics(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request->user(), $league);
        $rules = [];
        foreach (Tactics::RULES as $key => $rule) {
            $rules[$key] = is_int($rule[0]) ? ['sometimes', 'integer', "between:{$rule[0]},{$rule[1]}"] : ['sometimes', Rule::in($rule)];
        }
        $data = array_map(fn ($v) => is_numeric($v) ? (int) $v : $v, $request->validate($rules));
        Tactics::save($club, $data);

        return $this->tactics($request, $league);
    }

    /**
     * My next match [PLAN 2.13]: when, where, the referee once drawn, and the opponent. Before the lock the
     * opponent is only a club; after it, his eleven, formation and four tactics (tackling, marking, plan,
     * trap) are shown. Pressing, style, tempo, positions and the defensive shape are never sent.
     */
    public function nextMatch(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request->user(), $league);
        $f = $this->nextFixture($club);
        if (! $f) {
            return response()->json(['match' => null]);
        }
        $home = $f->home_id === $club->id;
        $opponent = Club::with('user')->find($home ? $f->away_id : $f->home_id);
        $sheets = DB::table('fixture_sheets')->where('fixture_id', $f->id)->get()->keyBy('club_id');
        $names = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->whereIn('players.club_id', [$club->id, $opponent->id])->pluck('master_players.name', 'players.id');
        $mine = $sheets[$club->id] ?? null;
        $theirs = $sheets[$opponent->id] ?? null;
        $at = Carbon::parse($f->scheduled_at, 'UTC');

        return response()->json(['match' => [
            'fixture_id' => $f->id, 'match_id' => DB::table('matches')->where('fixture_id', $f->id)->value('id'), 'competition' => $f->competition, 'round' => $f->round, 'venue' => $home ? 'home' : 'away',
            'scheduled_at' => $at->toIso8601ZuluString(), 'status' => $f->status,
            'referee_at' => $at->copy()->subMinutes(config('game.match.referee_minutes_before'))->toIso8601ZuluString(),
            'lock_at' => $at->copy()->subMinutes(config('game.match.lock_minutes_before'))->toIso8601ZuluString(),
            'referee' => $f->referee_strictness,
            // My club beside the opponent, for the VS card [X29].
            'club' => ['id' => $club->id, 'name' => $club->name, 'code' => $club->code, 'strength_cp' => (int) $club->strength_snapshot,
                'crest_url' => url("/api/v1/data/clubs/{$club->master_club_id}/crest.svg")],
            'opponent' => [
                'id' => $opponent->id, 'name' => $opponent->name, 'code' => $opponent->code, 'strength_cp' => (int) $opponent->strength_snapshot,
                'crest_url' => url("/api/v1/data/clubs/{$opponent->master_club_id}/crest.svg"), 'coach' => $opponent->user?->name,
                // Only after the lock, and only these.
                'sheet' => $theirs ? [
                    'formation' => $theirs->formation,
                    'starters' => collect(json_decode($theirs->starters))->map(fn ($id) => ['id' => $id, 'name' => $names[$id] ?? null])->all(),
                    'tactics' => Tactics::public(json_decode($theirs->tactics, true)),
                ] : null,
            ],
            'mine' => $mine ? [
                'formation' => $mine->formation, 'starters' => json_decode($mine->starters), 'bench' => json_decode($mine->bench),
                'tactics' => json_decode($mine->tactics, true),
                'fixes' => collect(json_decode($mine->fixes, true))->map(fn ($x) => $x + ['out_name' => $names[$x['out']] ?? null, 'in_name' => $names[$x['in']] ?? null])->all(),
            ] : null,
        ]]);
    }

    private function nextFixture(Club $club): ?object
    {
        return DB::table('fixtures')->whereIn('status', ['scheduled', 'locked', 'live'])->where('is_bye', false)
            ->where(fn ($q) => $q->where('home_id', $club->id)->orWhere('away_id', $club->id))
            ->whereNotNull('home_id')->whereNotNull('away_id')->orderBy('scheduled_at')->first();
    }

    /** The club's money [Sprint 23 W1]: the balance, the debt count, the movements, the sponsors and the gate. */
    public function finance(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request->user(), $league);
        $season = $league->season;
        $scale = Economy::scale($league->id);
        $money = Money::fromConfig();
        $cfg = config('game.economy');
        $chosen = DB::table('sponsor_contracts')->where('club_id', $club->id)->where('season_id', $season->id)->pluck('offer', 'sector');
        [$min, $max] = Economy::strengthRange($league->id);
        $attendance = $money->attendance((int) $club->strength_snapshot, $min, $max);
        $rows = DB::table('club_transactions')->where('club_id', $club->id)->orderByDesc('id')->limit(60)->get();
        // Each match's movements carry their round (a cup match its stage), for the ledger and the chart.
        $all = DB::table('club_transactions')->where('club_id', $club->id)->where('reference', 'like', 'fixture:%')->get(['amount', 'reference']);
        $fixtures = DB::table('fixtures')->whereIn('id', $all->pluck('reference')->merge($rows->pluck('reference'))->filter(fn ($r) => str_starts_with((string) $r, 'fixture:'))
            ->map(fn ($r) => (int) substr($r, 8))->unique())->get(['id', 'round', 'competition'])->keyBy('id');
        $roundOf = function (?string $ref) use ($fixtures) {
            $f = $ref && str_starts_with($ref, 'fixture:') ? $fixtures[(int) substr($ref, 8)] ?? null : null;

            return $f ? ['round' => $f->competition === 'league' ? (int) $f->round : null, 'cup' => $f->competition !== 'league'] : ['round' => null, 'cup' => false];
        };
        $perRound = [];
        foreach ($all as $t) {
            $r = $roundOf($t->reference)['round'];
            if ($r) {
                $perRound[$r] ??= ['round' => $r, 'in' => 0, 'out' => 0];
                $perRound[$r][$t->amount >= 0 ? 'in' : 'out'] += abs((int) $t->amount);
            }
        }
        ksort($perRound);
        $since = DB::table('club_transactions')->where('club_id', $club->id)->where('created_at', '>=', $season->created_at ?? '1970-01-01')
            ->groupBy('type')->selectRaw('type, sum(amount) as total')->pluck('total', 'type');

        return response()->json([
            'balance' => (int) $club->balance,
            'can_spend' => $club->balance >= 0,
            'debt_rounds' => (int) $club->debt_rounds,
            'debt_limit' => (int) $cfg['debt_rounds_before_forced_sale'],
            'wages_per_round' => $money->wages(Economy::squadValue($club->id), $season->rounds),
            'season_totals' => collect(ClubLedger::LABELS)->map(fn ($label, $type) => ['type' => $type, 'label' => $label, 'total' => (int) ($since[$type] ?? 0)])
                ->filter(fn ($t) => $t['total'] !== 0)->values(),
            // What the season earned and spent: the opening budget and a handover's change are neither.
            'season_income' => (int) collect($since)->except(ClubLedger::START)->filter(fn ($v) => $v > 0)->sum(),
            'season_expenses' => (int) collect($since)->except(ClubLedger::START)->filter(fn ($v) => $v < 0)->sum(),
            'rounds' => array_values($perRound),
            'transactions' => $rows->map(fn ($t) => ['id' => $t->id, 'type' => $t->type, 'label' => ClubLedger::LABELS[$t->type] ?? $t->type,
                'amount' => (int) $t->amount, 'balance_after' => (int) $t->balance_after, 'created_at' => Carbon::parse($t->created_at, 'UTC')->toIso8601ZuluString()]
                + $roundOf($t->reference)),
            'stadium' => ['capacity' => Stadium::capacity($club->id), 'attendance_bp' => $attendance, 'ticket_price' => $money->ticketPrice($scale, $season->rounds),
                'tickets_per_match' => $money->tickets($scale, $season->rounds, $attendance, Stadium::capacity($club->id))],
            'sponsors' => collect($cfg['sectors'])->map(fn ($share, $sector) => [
                'sector' => $sector, 'name' => self::SECTORS[$sector], 'chosen' => $chosen[$sector] ?? null,
                'offers' => collect($cfg['sponsor_offers'])->map(fn ($o, $key) => ['offer' => $key, 'name' => self::OFFERS[$key],
                    'per_match' => $money->sponsor($scale, $season->rounds, $sector, $key, false),
                    'per_win' => $money->sponsor($scale, $season->rounds, $sector, $key, true) - $money->sponsor($scale, $season->rounds, $sector, $key, false)])->values(),
            ])->values(),
        ]);
    }

    /** Sign a sector's sponsor for the season [PLAN 2.7]: once per sector. */
    public function signSponsor(Request $request, League $league): JsonResponse
    {
        $club = $this->club($request->user(), $league);
        $data = $request->validate([
            'sector' => ['required', Rule::in(array_keys(config('game.economy.sectors')))],
            'offer' => ['required', Rule::in(Economy::OFFERS)],
        ]);
        Economy::sign($club->id, $league->season->id, $data['sector'], $data['offer']);

        return $this->finance($request, $league);
    }

    private const SECTORS = ['main' => 'المدرج الرئيسي', 'opposite' => 'المدرج المقابل', 'north' => 'المدرج الشمالي', 'south' => 'المدرج الجنوبي'];

    private const OFFERS = ['steady' => 'ثابت', 'bonus' => 'متوازن مع مكافأة فوز', 'ambitious' => 'طموح: أقل ثابتاً وأكثر عند الفوز'];

    /** My club in this league; 403 without one. */
    private function club(User $user, League $league): Club
    {
        $club = Club::where('league_id', $league->id)->where('user_id', $user->id)->first();
        abort_unless($club, 403, 'ليس لديك فريق في هذا الدوري.');

        return $club;
    }

    /** Each player's card: attributes, potential, fitness, value, and whether he can play [PLAN 2.15]. */
    private function players(Club $club)
    {
        $camp = Camp::awayIds($club->id);

        return DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.club_id', $club->id)
            ->select('players.*', 'master_players.name', 'master_players.position', 'master_players.alt_positions', 'master_players.line', 'master_players.age',
                'master_players.nationality', 'master_players.preferred_foot', 'master_players.potential',
                'master_players.pac', 'master_players.sho', 'master_players.pas', 'master_players.dri', 'master_players.def', 'master_players.phy',
                'master_players.gk_diving', 'master_players.gk_handling', 'master_players.gk_kicking', 'master_players.gk_positioning', 'master_players.gk_reflexes')
            ->orderByRaw("case master_players.line when 'gk' then 0 when 'def' then 1 when 'mid' then 2 else 3 end")->orderByDesc('players.overall')->get()
            ->map(fn ($r) => (object) (Training::boosted((array) $r) + ['in_camp' => in_array($r->id, $camp, true)]))
            ->map(fn ($p) => [
                'id' => $p->id, 'name' => $p->name, 'position' => $p->position, 'alt_positions' => $p->alt_positions, 'line' => $p->line,
                'age' => $p->age, 'nationality' => $p->nationality, 'foot' => $p->preferred_foot,
                'overall' => $p->overall, 'training_bonus' => (int) $p->training_bonus, 'potential' => $p->potential, 'value' => (int) $p->value, 'fitness' => $p->fitness,
                'injured_matches' => $p->injured_matches, 'suspended_matches' => $p->suspended_matches,
                'in_camp' => $p->in_camp,
                'available' => $p->injured_matches === 0 && $p->suspended_matches === 0 && ! $p->in_camp,
                'attributes' => $p->line === 'gk'
                    ? ['diving' => $p->gk_diving, 'handling' => $p->gk_handling, 'kicking' => $p->gk_kicking, 'positioning' => $p->gk_positioning, 'reflexes' => $p->gk_reflexes]
                    : ['pac' => $p->pac, 'sho' => $p->sho, 'pas' => $p->pas, 'dri' => $p->dri, 'def' => $p->def, 'phy' => $p->phy],
            ]);
    }

    /**
     * The team's strength by line [X29], as the squad screen's four rings: the average rating of the starters in each
     * line (with their training), or of the line's best when no starter plays there. Integers, rounded down.
     */
    private function lineStrength($players): array
    {
        $out = [];
        foreach (['att' => 2, 'mid' => 4, 'def' => 4, 'gk' => 1] as $line => $n) {
            $all = $players->where('line', $line);
            $pick = $all->where('role', 'starter');
            $pick = $pick->isEmpty() ? $all->sortByDesc('overall')->take($n) : $pick;
            $out[$line] = $pick->isEmpty() ? 0 : intdiv((int) $pick->sum('overall'), $pick->count());
        }

        return $out;
    }

    private function lineup(array $l): array
    {
        return ['formation' => $l['formation'], 'auto' => $l['auto'], 'slots' => $l['slots'], 'starters' => $l['starters'], 'bench' => $l['bench'],
            'lines' => FormationBook::lines($l['slots'])];
    }

    private function formation(string $name, string $label, array $slots): array
    {
        return ['name' => $name, 'label' => $label, 'slots' => $slots, 'lines' => FormationBook::lines($slots)];
    }
}
