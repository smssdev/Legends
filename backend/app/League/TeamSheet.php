<?php

namespace App\League;

use App\Engine\Ability;
use App\Engine\AutoPick;
use App\Engine\MatchSetup;
use App\Models\Club;
use App\Support\GameClock;
use App\Training\Training;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * A club's team sheet [PLAN 2.15, 2.16]: the lineup in a formation, the bench, the club's own formations
 * and the set-piece takers. Every rule is checked here, on the server, with an Arabic message. A club with
 * no saved lineup (a bot, or a coach who never set one) gets "تحسين": the best eleven by strength and
 * fitness across the 24 formations, the same choice the bot makes [Sprint 16 B3].
 */
class TeamSheet
{
    public const BENCH = 7;

    public const CUSTOM_MAX = 3;

    /** The captain and the set-piece takers. */
    public const ROLES = ['captain', 'penalty', 'free_kick', 'corner'];

    /** The line of each position [X5]: a player plays in his own line, or in one his other positions belong to. */
    public const POSITION_LINE = [
        'GK' => 'gk', 'CB' => 'def', 'LB' => 'def', 'RB' => 'def', 'LWB' => 'def', 'RWB' => 'def',
        'CDM' => 'mid', 'CM' => 'mid', 'CAM' => 'mid', 'LM' => 'mid', 'RM' => 'mid',
        'LW' => 'att', 'RW' => 'att', 'ST' => 'att', 'CF' => 'att',
    ];

    public const LINE_NAME = ['gk' => 'حراسة المرمى', 'def' => 'الدفاع', 'mid' => 'الوسط', 'att' => 'الهجوم'];

    /** The lines a player may stand in: his position's, and his other positions' (a CB who also plays CDM). */
    public static function linesOf(array $p): array
    {
        $lines = [$p['line'] => true];
        foreach (array_map('trim', explode(',', (string) ($p['alt'] ?? ''))) as $alt) {
            if (isset(self::POSITION_LINE[$alt])) {
                $lines[self::POSITION_LINE[$alt]] = true;
            }
        }

        return array_keys($lines);
    }

    /**
     * [Sprint 27 X2] What a player of this line gives in each line (bp of his ability), from the engine itself
     * (App\Engine\Ability::position: his own line in full, the next one 70% and two lines away 50% [Sprint 38 E1], the
     * goal far less; a winger, or a second position, is in full in its line too).
     *
     * @return array{gk: int, def: int, mid: int, att: int}
     */
    public static function placeBp(string $line, string $position = '', ?string $alt = null): array
    {
        $out = [];
        foreach (['gk', 'def', 'mid', 'att'] as $at) {
            $out[$at] = Ability::position(['line' => $line, 'slot_line' => $at, 'pos' => $position, 'alt' => (string) $alt]);
        }

        return $out;
    }

    /** Out of his lines: so far out that "تحسين" puts him there only when nobody else is left. */
    public const OFF_LINE = 1000000;

    /** The squad in the engine's shape (App\Engine\MatchSetup::player), with the league's own numbers. */
    public static function squad(Club $club): array
    {

        return DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('players.club_id', $club->id)
            ->select('master_players.*', 'players.id', 'players.overall', 'players.training_bonus', 'players.fitness', 'players.injured_matches', 'players.suspended_matches')
            ->orderBy('players.id')->get()
            ->map(function ($r) {
                $p = MatchSetup::player(Training::boosted((array) $r));
                $p['fitness'] = (int) $r->fitness;
                $p['unavailable'] = $r->injured_matches > 0 || $r->suspended_matches > 0;

                return $p;
            })->all();
    }

    /** The formations this club can pick: the 24, then its own. name => slots. */
    public static function formations(Club $club): array
    {
        $all = [];
        foreach (FormationBook::names() as $name) {
            $all[$name] = FormationBook::slots($name);
        }
        foreach (self::customs($club) as $c) {
            $all['custom:'.$c['number']] = FormationBook::custom($c['cells']);
        }

        return $all;
    }

    public static function customs(Club $club): array
    {
        return DB::table('custom_formations')->where('club_id', $club->id)->orderBy('number')->get()
            ->map(fn ($c) => ['number' => $c->number, 'name' => $c->name, 'cells' => json_decode($c->cells, true)])->all();
    }

    /**
     * The lineup as it stands: saved, or picked now. Players gone since (sold, later) leave their slot empty.
     *
     * @return array{formation: string, auto: bool, slots: list<array>, starters: list<?int>, bench: list<int>}
     */
    public static function current(Club $club): array
    {
        $formations = self::formations($club);
        $saved = DB::table('lineups')->where('club_id', $club->id)->first();
        if (! $saved || ! isset($formations[$saved->formation])) {
            return self::best($club) + ['auto' => true];
        }
        $slots = $formations[$saved->formation];
        if ($saved->positions) {
            try {
                $slots = FormationBook::moved($slots, json_decode($saved->positions, true));
            } catch (\InvalidArgumentException) {
                // A formation changed since: its own places.
            }
        }
        $at = DB::table('lineup_slots')->where('lineup_id', $saved->id)->pluck('player_id', 'position');
        $mine = DB::table('players')->where('club_id', $club->id)->pluck('id')->flip();
        $starters = [];
        for ($i = 0; $i < 11; $i++) {
            $starters[] = isset($at[$i], $mine[$at[$i]]) ? (int) $at[$i] : null;
        }
        $bench = $at->filter(fn ($id, $pos) => $pos >= 11 && isset($mine[$id]))->sortKeys()->values()->map(fn ($id) => (int) $id)->all();

        return ['formation' => $saved->formation, 'slots' => $slots, 'starters' => $starters, 'bench' => $bench, 'auto' => false];
    }

    /**
     * "تحسين": for each formation, the best (player, slot) pairs first by strength, fitness and fit (as the
     * engine's own AutoPick does), then the formation with the best total; a small preference for four at
     * the back breaks near ties. Unavailable players (injured, suspended) are left out.
     */
    /** @param  list<string>|null  $formations  only these (the assistant's balanced ones [UP13]), else every one */
    public static function best(Club $club, int $restBelow = 0, ?array $formations = null): array
    {
        $squad = array_values(array_filter(self::squad($club), fn ($p) => ! $p['unavailable']));
        // Rotation (the bots, Sprint 32): the tired rest while two keepers and fourteen others are still there.
        if ($restBelow) {
            $fresh = array_values(array_filter($squad, fn ($p) => $p['fitness'] >= $restBelow));
            $keepers = count(array_filter($fresh, fn ($p) => $p['line'] === 'gk'));
            if ($keepers >= 1 && count($fresh) - $keepers >= 14) {
                $squad = $fresh;
            }
        }
        $best = null;
        foreach ($formations ?? FormationBook::names() as $name) {
            $slots = FormationBook::slots($name);
            [$score, $starters] = self::fill($squad, $slots);
            $score += FormationBook::lines($slots)['def'] === 4 ? 300 : 0;
            if ($best === null || $score > $best[0]) {
                $best = [$score, $starters, $name, $slots];
            }
        }
        [, $starters, $name, $slots] = $best;
        $chosen = array_flip(array_filter($starters));
        $rest = array_values(array_filter($squad, fn ($p) => ! isset($chosen[$p['id']])));
        usort($rest, fn ($a, $b) => self::value($b) <=> self::value($a) ?: $a['id'] <=> $b['id']);
        $bench = [];
        foreach ($rest as $p) {
            if ($p['line'] === 'gk') {
                $bench[] = $p['id'];
                break;
            }
        }
        foreach ($rest as $p) {
            if (count($bench) < self::BENCH && ! in_array($p['id'], $bench, true)) {
                $bench[] = $p['id'];
            }
        }

        return ['formation' => $name, 'slots' => $slots, 'starters' => $starters, 'bench' => $bench];
    }

    /** Strength counts, and a tired player less: overall × 100, minus up to 20 points at zero fitness. */
    private static function value(array $p): int
    {
        return $p['a']['ovr'] * 100 - intdiv((100 - $p['fitness']) * 2000, 100);
    }

    private static function fill(array $players, array $slots): array
    {
        $pairs = [];
        foreach ($slots as $i => $slot) {
            $fit = ['line' => $slot['line'], 'fits' => self::fits($slot['role'])];
            foreach ($players as $p) {
                $off = in_array($slot['line'], self::linesOf($p), true) ? 0 : self::OFF_LINE;
                $pairs[] = [self::value($p) - AutoPick::misfit($p, $fit) - $off, $i, $p['id']];
            }
        }
        usort($pairs, fn ($a, $b) => $b[0] <=> $a[0] ?: $a[1] <=> $b[1] ?: $a[2] <=> $b[2]);
        $starters = array_fill(0, count($slots), null);
        $used = [];
        $score = 0;
        foreach ($pairs as [$value, $slot, $id]) {
            if ($starters[$slot] !== null || isset($used[$id])) {
                continue;
            }
            $starters[$slot] = $id;
            $used[$id] = true;
            $score += $value;
        }

        return [$score, $starters];
    }

    /** The positions that fit a role, as the engine's own slots name them. */
    public static function fits(string $role): array
    {
        return [
            'GK' => ['GK'], 'LB' => ['LB', 'LWB'], 'RB' => ['RB', 'RWB'], 'CB' => ['CB'], 'LWB' => ['LB', 'LWB'], 'RWB' => ['RB', 'RWB'],
            'CDM' => ['CDM', 'CM'], 'CM' => ['CM', 'CDM', 'CAM'], 'CAM' => ['CAM', 'CM'], 'LM' => ['LM', 'LW'], 'RM' => ['RM', 'RW'],
            'LW' => ['LW', 'LM'], 'RW' => ['RW', 'RM'], 'ST' => ['ST', 'CF'],
        ][$role];
    }

    /**
     * Save the coach's lineup: a formation, eleven players in its slots, and up to seven on the bench. The coach may
     * drag the ten outfield places anywhere inside their lines' bands ($positions) [X5]. [Sprint 27] An outfield
     * player may stand in any line, out of his own at a lower share.
     */
    public static function save(Club $club, string $formation, array $starters, array $bench, ?array $positions = null): void
    {
        MatchPrep::assertOpen($club);
        $formations = self::formations($club);
        if (! isset($formations[$formation])) {
            throw ValidationException::withMessages(['formation' => __('هذه الطريقة غير موجودة.')]);
        }
        $slots = $formations[$formation];
        if ($positions !== null) {
            try {
                $slots = FormationBook::moved($slots, $positions);
            } catch (\InvalidArgumentException $e) {
                throw ValidationException::withMessages(['positions' => $e->getMessage()]);
            }
        }
        if (count($starters) !== 11 || in_array(null, $starters, true)) {
            throw ValidationException::withMessages(['starters' => __('التشكيلة 11 لاعباً بالضبط.')]);
        }
        if (count($bench) > self::BENCH) {
            throw ValidationException::withMessages(['bench' => sprintf(__('الاحتياط %d لاعبين على الأكثر.'), self::BENCH)]);
        }
        $all = array_merge($starters, $bench);
        if (count($all) !== count(array_unique($all))) {
            throw ValidationException::withMessages(['starters' => __('لاعب واحد لا يكون في خانتين.')]);
        }
        $squad = collect(self::squad($club))->keyBy('id');
        foreach ($all as $id) {
            if (! $squad->has($id)) {
                throw ValidationException::withMessages(['starters' => __('كل اللاعبين يجب أن يكونوا من فريقك.')]);
            }
        }
        if ($squad[$starters[0]]['line'] !== 'gk') {
            throw ValidationException::withMessages(['starters' => __('خانة الحارس لحارس مرمى.')]);
        }
        // [Sprint 27 W4, the owner's request 2026-10-30: as flexible as OSM] Any outfield player in any outfield place:
        // out of his lines he plays at the engine's own out-of-position share (App\Engine\Ability::position), and the
        // screen says so. Only the goal is kept for a goalkeeper, and a goalkeeper for the goal.
        foreach ($starters as $i => $id) {
            if ($i > 0 && $squad[$id]['line'] === 'gk') {
                throw ValidationException::withMessages(['starters' => sprintf(__('%s حارس مرمى: مكانه في المرمى أو على الدكة.'), $squad[$id]['name'])]);
            }
        }
        $moved = $positions === null ? null : json_encode(array_map(fn ($s) => [$s['x'], $s['y']], array_slice($slots, 1)));
        DB::transaction(function () use ($club, $formation, $starters, $bench, $moved) {
            $now = GameClock::now();
            DB::table('lineups')->upsert([['club_id' => $club->id, 'formation' => $formation, 'positions' => $moved, 'created_at' => $now, 'updated_at' => $now]], ['club_id'], ['formation', 'positions', 'updated_at']);
            $id = DB::table('lineups')->where('club_id', $club->id)->value('id');
            DB::table('lineup_slots')->where('lineup_id', $id)->delete();
            $rows = [];
            foreach (array_merge($starters, $bench) as $position => $player) {
                $rows[] = ['lineup_id' => $id, 'position' => $position, 'player_id' => $player];
            }
            DB::table('lineup_slots')->insert($rows);
        });
    }

    /** Save one of the club's own formations (1 to 3) from its ten outfield cells, within the line limits. */
    public static function saveCustom(Club $club, int $number, string $name, array $cells): void
    {
        if ($number < 1 || $number > self::CUSTOM_MAX) {
            throw ValidationException::withMessages(['number' => sprintf(__('لك %d تشكيلات مخصصة فقط.'), self::CUSTOM_MAX)]);
        }
        $keys = array_map(fn ($c) => implode(':', $c), $cells);
        if (count($cells) !== 10 || count($keys) !== count(array_unique($keys))) {
            throw ValidationException::withMessages(['cells' => __('ضع 10 لاعبين في خانات مختلفة (والحارس ثابت).')]);
        }
        if ($error = FormationBook::invalid(FormationBook::custom($cells))) {
            throw ValidationException::withMessages(['cells' => $error]);
        }
        $now = GameClock::now();
        DB::table('custom_formations')->upsert([['club_id' => $club->id, 'number' => $number, 'name' => $name, 'cells' => json_encode($cells),
            'created_at' => $now, 'updated_at' => $now]], ['club_id', 'number'], ['name', 'cells', 'updated_at']);
    }

    /**
     * The captain and set-piece takers [PLAN 2.16]: the coach's choice when still a starter, else the
     * automatic one among the starters (as AutoPick::takers chooses for the engine). [Sprint 27 W5] The coach may
     * choose anyone in the squad (chosen_id): out of the eleven, the automatic one takes the role until he is back.
     * Each role's candidates come ranked by its skill (captain: experience and rating; the others: penalties,
     * free kicks, crossing), for the specialists' cards.
     */
    public static function takers(Club $club, ?array $lineup = null): array
    {
        $lineup ??= self::current($club);
        $on = array_flip(array_filter($lineup['starters']));
        $squad = array_map(fn ($p) => $p + ['on' => isset($on[$p['id']])], self::squad($club));
        $auto = AutoPick::takers($squad);
        $set = DB::table('set_piece_takers')->where('club_id', $club->id)->first();
        $out = [];
        foreach (self::ROLES as $role) {
            $skill = fn ($p) => self::skill($role, $p);
            $chosen = $set?->{$role.'_id'};
            $field = array_filter($squad, fn ($p) => $p['line'] !== 'gk' || $role === 'captain');
            usort($field, fn ($a, $b) => $skill($b) <=> $skill($a) ?: $a['id'] <=> $b['id']);
            $out[$role] = ['player_id' => $chosen && isset($on[$chosen]) ? (int) $chosen : $auto[$role], 'auto' => ! ($chosen && isset($on[$chosen])),
                'chosen_id' => $chosen ? (int) $chosen : null,
                'candidates' => array_map(fn ($p) => ['id' => (int) $p['id'], 'skill' => $skill($p), 'on' => $p['on']], array_values($field))];
        }

        return $out;
    }

    /** The takers as a locked sheet keeps them: each role's player and whether he is automatic. */
    public static function sheetTakers(Club $club, ?array $lineup = null): array
    {
        return array_map(fn ($t) => ['player_id' => $t['player_id'], 'auto' => $t['auto']], self::takers($club, $lineup));
    }

    /** A role's skill, 0 to 99: the captain's is the rating, a little more with age; the others the engine's own. */
    public static function skill(string $role, array $p): int
    {
        return match ($role) {
            'captain' => min(99, (int) $p['a']['ovr'] + intdiv(max(0, (int) $p['age'] - 22), 2)),
            'penalty' => (int) ($p['a']['pen'] ?? 0),
            'free_kick' => (int) ($p['a']['fk'] ?? 0),
            default => (int) ($p['a']['cross'] ?? 0),
        };
    }

    /** The coach's takers; null for a role leaves it automatic ("تحسين" clears them all). */
    public static function saveTakers(Club $club, array $takers): void
    {
        MatchPrep::assertOpen($club);
        $mine = array_flip(array_column(self::squad($club), 'id'));
        foreach ($takers as $role => $id) {
            if ($id !== null && ! isset($mine[$id])) {
                throw ValidationException::withMessages([$role => __('المنفذ يجب أن يكون من فريقك.')]);
            }
        }
        $now = GameClock::now();
        $row = ['club_id' => $club->id, 'created_at' => $now, 'updated_at' => $now];
        foreach (self::ROLES as $role) {
            $row[$role.'_id'] = $takers[$role] ?? null;
        }
        DB::table('set_piece_takers')->upsert([$row], ['club_id'], ['captain_id', 'penalty_id', 'free_kick_id', 'corner_id', 'updated_at']);
    }
}
