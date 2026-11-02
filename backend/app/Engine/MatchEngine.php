<?php

namespace App\Engine;

/**
 * Simulates one minute of play (docs/ENGINE.md). Pure and deterministic:
 * the same state, actions and random stream always give the same result. It
 * never touches the database or config(): every number comes from the
 * config snapshot inside the state. Integers only.
 *
 * Tactics never add strength directly. They change what happens: how often a
 * team attacks, how many build-ups the press breaks, counters, offsides,
 * fouls and fatigue. The result comes from those visible causes.
 */
final class MatchEngine
{
    /** Attribute mix used in the progress phase for each attack plan. */
    private const PLAN_MIX = ['counter' => 'counter', 'long' => 'long', 'passing' => 'passing', 'wings' => 'wings', 'shots' => 'shots'];

    private array $s;

    private SeededRandom $rng;

    private array $events = [];

    private array $debug = [];

    private array $cfg;

    private array $eng;

    private int $danger = 0;

    public static function simulateTick(array $state, array $actions, SeededRandom $rng): array
    {
        return (new self($state, $rng))->run($actions);
    }

    private function __construct(array $state, SeededRandom $rng)
    {
        $this->s = $state;
        $this->rng = $rng;
        $this->cfg = $state['cfg']['match'];
        $this->eng = $state['cfg']['engine'];
    }

    private function run(array $actions): array
    {
        if ($this->s['finished']) {
            return $this->s + ['out' => ['tick' => $this->s['tick'], 'events' => []]];
        }

        $this->s['tick']++;
        $rejected = [];
        foreach ($actions as $action) {
            $error = Actions::apply($this->s, $action);
            if ($error !== null) {
                $rejected[] = ['action' => $action, 'reason' => $error];
            } else {
                $this->event('action', $action['team'], ['action' => $action]);
            }
        }
        $this->fillInjured();

        if ($this->s['period'] === 5) {
            $this->shootout();
        } else {
            $this->s['pmin']++;
            $this->playMinute();
            $this->fatigue();
            $label = $this->minuteLabel();
            $period = $this->s['period'];
            $this->clock();
        }

        unset($this->s['out']);
        $out = [
            'tick' => $this->s['tick'],
            'period' => $period ?? $this->s['period'],
            'minute' => $label ?? $this->minuteLabel(),
            'score' => $this->s['score'],
            'events' => $this->events,
            'danger' => $this->danger,
            'rejected' => $rejected,
            'debug' => $this->debug,
            'finished' => $this->s['finished'],
        ];
        $this->s['out'] = $out;
        FloatGuard::check($this->s);

        return $this->s;
    }

    // ---------------------------------------------------------------- clock

    private function periodLength(int $period): int
    {
        return $period <= 2 ? (int) $this->cfg['half_length'] : (int) $this->cfg['extra_half_length'];
    }

    private function periodStart(int $period): int
    {
        return [1 => 0, 2 => 45, 3 => 90, 4 => 105][$period] ?? 120;
    }

    /** Display minute: [base minute, added minutes]. */
    private function minuteLabel(): array
    {
        $period = $this->s['period'];
        $len = $this->periodLength($period);
        $pmin = min($this->s['pmin'], $len + ($this->s['stoppage'][$period] ?? 0));
        if ($period === 5) {
            return [120, 0];
        }

        return $pmin <= $len
            ? [$this->periodStart($period) + $pmin, 0]
            : [$this->periodStart($period) + $len, $pmin - $len];
    }

    private function clock(): void
    {
        $period = $this->s['period'];
        $len = $this->periodLength($period);

        if ($this->s['pmin'] === $len) {
            [$min, $max] = $this->eng['stoppage'][$period];
            $busy = intdiv($this->periodEvents, 6);
            $added = max($min, min($max, $min + $busy + $this->rng->int(2)));
            $this->s['stoppage'][$period] = $added;
            $this->event('stoppage', null, ['added' => $added]);
        }

        if ($this->s['pmin'] < $len + $this->s['stoppage'][$period]) {
            return;
        }

        $draw = $this->s['score']['home'] === $this->s['score']['away'];
        $cup = $this->s['competition'] === 'cup';
        $this->s['pmin'] = 0;
        $this->s['busy'] = 0;

        if ($period === 1) {
            $this->s['period'] = 2;
            $this->event('period', null, ['name' => 'halftime']);
        } elseif ($period === 2 && $cup && $draw) {
            $this->s['period'] = 3;
            foreach (['home', 'away'] as $side) {
                $this->s['teams'][$side]['subs_max'] += (int) ($this->cfg['extra_time_subs'] ?? 1);
            }
            $this->event('period', null, ['name' => 'extra_time']);
        } elseif ($period === 3) {
            $this->s['period'] = 4;
            $this->event('period', null, ['name' => 'extra_time_half']);
        } elseif ($period === 4 && $draw) {
            $this->s['period'] = 5;
            $this->event('period', null, ['name' => 'penalties']);
        } else {
            $this->finish();
        }
    }

    private int $periodEvents = 0;

    private function finish(): void
    {
        $this->s['finished'] = true;
        $this->event('period', null, ['name' => 'fulltime', 'score' => $this->s['score']]);
    }

    // ---------------------------------------------------------------- play

    private function playMinute(): void
    {
        $this->periodEvents = (int) ($this->s['busy'] ?? 0);
        $home = $this->s['teams']['home'];
        $away = $this->s['teams']['away'];

        $tempo = $home['tactics']['tempo'] + $away['tactics']['tempo'] - 100;
        $rate = intdiv((int) $this->eng['attack_rate_bp'] * (10000 + $tempo * 25), 10000);
        $minute = $this->minuteLabel()[0];
        if ($minute > 75 && $this->s['period'] === 2) {
            $rate += ($minute - 75) * (int) $this->eng['late_open_bp_per_minute'];
        }
        $rate = max(3500, min(8000, $rate));

        $midDiff = $this->ability('home', 'build', Ability::LINES['passing']) - $this->ability('away', 'build', Ability::LINES['passing']);
        $share = 5000 + intdiv($midDiff * (int) $this->eng['share_slope_bp'], 100)
            + ($home['tactics']['style'] - $away['tactics']['style']) * (int) $this->eng['style_share_bp']
            + $this->gameState('home') - $this->gameState('away')
            + ($this->s['venue'] === 'home' ? (int) $this->eng['home_share_bp'] : 0);
        $share = max(2000, min(8000, $share));

        $roll = $this->rng->int(10000);
        $homeCut = intdiv($rate * $share, 10000);
        $this->debug['initiative'] = ['rate' => $rate, 'home_share' => $share];

        if ($roll < $homeCut) {
            $this->attack('home');
        } elseif ($roll < $rate) {
            $this->attack('away');
        } elseif ($this->rng->chance((int) $this->eng['midfield_foul_bp'])) {
            $this->midfieldFoul();
        }

        $this->s['momentum'][] = $this->danger;
        $this->s['busy'] = $this->periodEvents;
    }

    /** Trailing teams push after minute 60, and red cards cost initiative. */
    private function gameState(string $side): int
    {
        $other = $side === 'home' ? 'away' : 'home';
        $diff = $this->s['score'][$other] - $this->s['score'][$side];
        $minute = $this->minuteLabel()[0];
        $push = 0;
        if ($diff > 0 && $minute > (int) $this->eng['trailing_push_from_minute']) {
            $push = min(1500, ($minute - (int) $this->eng['trailing_push_from_minute']) * $diff * (int) $this->eng['trailing_push_bp_per_minute']);
        }

        return $push - $this->s['teams'][$side]['missing'] * 400;
    }

    /** Ability of a team's lines in a phase, with home advantage, captain and red cards. */
    private function ability(string $side, string $mix, array $lines): int
    {
        $team = $this->s['teams'][$side];
        $value = Ability::lines($team, $mix, $lines);
        if ($side === 'home' && $this->s['venue'] === 'home') {
            // The base advantage, and the home pitch's stage on top [PLAN 2.9].
            $value += intdiv($value * ((int) $this->cfg['home_base_bp'] + (int) ($this->cfg['home_pitch_bp'][$this->s['pitch'] ?? 0] ?? 0)), 10000);
        }
        $captain = $this->player($side, $team['takers']['captain'] ?? 0);
        if ($captain && $captain['on'] && $captain['fit'] > (int) $this->cfg['captain_min_fitness'] * 100) {
            $value += (int) $this->eng['captain_cp'];
        }

        return $value - $team['missing'] * (int) $this->eng['man_down_cp'];
    }

    private function phase(string $name, int $attack, int $defence, int $mod = 0, int $bp = 0): array
    {
        $base = (int) $this->eng['phase_base_bp'][$name];
        $p = $base + intdiv(($attack - $defence + $mod) * (int) $this->eng['phase_slope_bp'], 100) + $bp;
        $p = max((int) $this->eng['phase_floor_bp'], min((int) $this->eng['phase_ceiling_bp'], $p));
        $roll = $this->rng->int(10000);

        return ['p' => $p, 'ok' => $roll < $p, 'margin' => $p - $roll];
    }

    /** The defensive shape a side's tactics make: 0 high, 1 middle, 2 low (the tactics book reads the same rule). */
    public static function shape(array $tactics): int
    {
        $score = $tactics['pressing'] + intdiv($tactics['style'] - 50, 2) + ($tactics['trap'] ? 15 : 0)
            + ($tactics['def'] === 'mid' ? 5 : 0) - ($tactics['mid'] === 'def' ? 8 : 0);

        return $score >= 70 ? 0 : ($score <= 40 ? 2 : 1);
    }

    private function attack(string $atk, bool $counter = false): void
    {
        $def = $atk === 'home' ? 'away' : 'home';
        $A = $this->s['teams'][$atk];
        $D = $this->s['teams'][$def];
        $ta = $A['tactics'];
        $td = $D['tactics'];
        $plan = $counter ? 'counter' : $ta['plan'];
        $phases = [];
        $carrier = $this->pickPlayer($atk, ['def' => 2, 'mid' => 3], 'pas');
        $this->stat($atk, 'attacks');
        $this->danger = $atk === 'home' ? 1 : -1;
        $tempoLoss = max(0, $ta['tempo'] - 50) * (int) $this->eng['tempo_precision_cp'];
        $tackleBonus = (int) $this->eng['tackling_bonus_cp'][$td['tackling']];

        if (! $counter) {
            // Build-up against the press.
            $this->stat($atk, 'builds');
            $this->third($atk, 0);
            $a = $this->ability($atk, 'build', Ability::LINES['build']) - $tempoLoss + $this->posMod($ta, 'build');
            $d = $this->ability($def, 'press', Ability::LINES['press'])
                + ($td['pressing'] - 50) * (int) $this->eng['press_bonus_cp'] + $tackleBonus + $this->posMod($td, 'press');
            $r = $this->phase('build', $a, $d, 0, $this->chemistry($atk));
            $phases[] = ['n' => 'build', 'ok' => $r['ok'], 'p' => $r['p']];
            if (! $r['ok']) {
                $this->stat($atk, 'builds_lost');
                $this->stat($def, 'presses_won');
                $winner = $this->pickPlayer($def, ['att' => 2, 'mid' => 2], 'def');
                $this->rate($def, $winner, 8, 'tackles');
                $this->attackEvent($atk, $plan, false, $phases, 'lost', compact('carrier') + ['defender' => $winner]);
                $counterP = (int) $this->eng['counter_base_bp'] + ($td['pressing'] - 50) * 20
                    + ($td['plan'] === 'counter' ? $this->counterPlan($td, (int) $this->eng['counter_plan_bp']) : 0) + ($ta['style'] - 50) * 20;
                if ($this->rng->chance($counterP)) {
                    $this->stat($def, 'counters');
                    $this->attack($def, true);
                }

                return;
            }
            $this->rate($atk, $carrier, 3);
            $presser = $this->pickPlayer($def, ['att' => 2, 'mid' => 2], 'phy');
            $exposure = intdiv(max(0, $td['pressing'] - 30) * 10000, 70);
            if ($this->rng->chance(intdiv($exposure, 2) + 2500) && $this->foul($def, $atk, $presser, $carrier, $a - $d, 'build', $phases, $plan, $counter)) {
                return;
            }
        }

        // Progress: the attack plan against the defensive shape.
        $this->third($atk, 1);
        $this->danger = $atk === 'home' ? 2 : -2;
        $mix = self::PLAN_MIX[$plan] ?? 'passing';
        // The plan against the shape moves the odds of getting through and of making the chance, never the players
        // [Sprint 21 E5.4]. Long shots skip the chance, so their one gate carries both.
        $matchup = (int) ($this->eng['matchup_bp'][$this->planKey($plan)][self::shape($td)] ?? 0);
        // [Sprint 39 E4] The plan with the formation that suits it, and a defence whose settings pull it apart.
        $synergy = $counter ? 0 : $this->synergy($atk, $plan);
        $gaps = $this->gaps($def);
        $a = $this->ability($atk, $mix, Ability::LINES[$mix]) - $tempoLoss + $this->posMod($ta, 'progress')
            + ($counter ? (int) $this->eng['counter_bonus_cp'] : 0);
        $holdMix = $plan === 'counter' ? 'hold_counter' : 'hold';
        $d = $this->ability($def, $holdMix, Ability::LINES[$holdMix]) + $tackleBonus + $this->posMod($td, 'hold');
        $receiver = $this->pickPlayer($atk, $plan === 'wings' ? ['mid' => 2, 'att' => 2, 'def' => 1] : ['mid' => 2, 'att' => 3], $plan === 'counter' ? 'pac' : 'pas', [$carrier]);
        $marker = $this->pickPlayer($def, ['def' => 3, 'mid' => 1], 'def');
        $createBonus = 0;

        // The trap replaces the ordinary offsides only against balls in behind (long balls and counters).
        $trapped = $td['trap'] && in_array($plan, ['long', 'counter'], true);
        if (! $trapped && $this->rng->chance((int) ($this->eng['offside_bp'][$plan] ?? 300))) {
            $phases[] = ['n' => 'offside', 'ok' => false];
            $this->stat($atk, 'offsides');
            $this->attackEvent($atk, $plan, $counter, $phases, 'offside', ['carrier' => $carrier, 'receiver' => $receiver, 'defender' => $marker]);

            return;
        }

        if ($trapped) {
            $paceGap = $this->lineAttr($def, 'def', 'pac') - $this->lineAttr($atk, 'att', 'pac');
            // [Sprint 39 E5] A high line of three under a high press springs it; a deep four or five that tries it breaks.
            $deep = $this->count($def, 'def') >= 4 && $td['pressing'] < 50;
            $high = $this->count($def, 'def') <= 3 && $td['pressing'] >= 60;
            $trapP = (int) $this->eng['trap_base_bp'] + $paceGap * 40
                + ($high ? (int) $this->eng['trap_line_bp'] : 0) - ($deep ? (int) $this->eng['trap_line_bp'] : 0);
            if ($this->rng->chance(max(1500, min(6000, $trapP)))) {
                $phases[] = ['n' => 'offside', 'ok' => false];
                $this->stat($atk, 'offsides');
                $this->attackEvent($atk, $plan, $counter, $phases, 'offside', ['carrier' => $carrier, 'receiver' => $receiver, 'defender' => $marker]);

                return;
            }
            $createBonus = (int) $this->eng['trap_fail_bonus_cp'] + ($deep ? (int) $this->eng['trap_deep_fail_cp'] : 0);
        }

        $r = $this->phase('progress', $a, $d, 0, ($counter ? $this->chemistry($atk) : 0) + $this->morale($atk) - $this->morale($def)
            + ($plan === 'shots' ? 2 : 1) * ($matchup + $synergy) + $gaps);
        $phases[] = ['n' => 'progress', 'ok' => $r['ok'], 'p' => $r['p']];
        if (! $r['ok']) {
            $this->rate($def, $marker, 6, 'tackles');
            $this->attackEvent($atk, $plan, $counter, $phases, 'lost', ['carrier' => $carrier, 'receiver' => $receiver, 'defender' => $marker]);
            // Winning the ball in midfield also opens a counter, less often than a broken build-up.
            $counterP = intdiv((int) $this->eng['counter_base_bp'], 3) + ($td['plan'] === 'counter' ? $this->counterPlan($td, intdiv((int) $this->eng['counter_plan_bp'], 2)) : 0) + ($ta['style'] - 50) * 15;
            if (! $counter && $this->rng->chance($counterP)) {
                $this->stat($def, 'counters');
                $this->attack($def, true);
            }

            return;
        }
        $this->stat($atk, 'progress');
        $this->rate($atk, $receiver, 4);
        if ($this->foul($def, $atk, $marker, $receiver, $a - $d, 'progress', $phases, $plan, $counter)) {
            return;
        }

        // Chance creation at the box (long shots skip it).
        $this->third($atk, 2);
        $this->danger = $atk === 'home' ? 3 : -3;
        $creator = $receiver;
        $quality = 'long';
        $minute = $this->minuteLabel()[0];
        $lapse = $minute > 70 ? ($minute - 70) * (int) $this->eng['late_lapse_cp_per_minute'] : 0;
        $createBonus += $lapse;
        if ($plan !== 'shots') {
            $a = $this->ability($atk, 'create', Ability::LINES['create']) - $tempoLoss + $createBonus + $this->posMod($ta, 'create');
            $d = $this->ability($def, 'mark', Ability::LINES['mark']) + $this->markingMod($td, $A);
            $r = $this->phase('create', $a, $d, 0, $this->morale($atk) - $this->morale($def) - $this->chemistry($def) + $matchup + $synergy);
            $phases[] = ['n' => 'create', 'ok' => $r['ok'], 'p' => $r['p']];
            if (! $r['ok']) {
                $corner = $this->rng->chance(2500);
                $this->attackEvent($atk, $plan, $counter, $phases, $corner ? 'corner' : 'cleared', ['carrier' => $carrier, 'receiver' => $receiver, 'defender' => $marker]);
                if ($corner) {
                    $this->corner($atk);
                }

                return;
            }
            $this->stat($atk, 'chances');
            $this->rate($atk, $creator, 15, 'key');
            $quality = $r['margin'] >= 4500 ? 'big' : ($r['margin'] >= 2000 ? 'normal' : 'half');
            if (($counter || $createBonus > 0) && $quality !== 'big') {
                $quality = $quality === 'half' ? 'normal' : 'big';
            }
            if ($this->foul($def, $atk, $marker, $creator, $a - $d, 'create', $phases, $plan, $counter, $quality)) {
                return;
            }
        }

        $shooter = $this->pickPlayer($atk, $plan === 'shots' ? ['mid' => 3, 'att' => 2] : ['att' => 6, 'mid' => 3, 'def' => 1], 'sho');
        $this->shot($atk, $shooter, $quality, $phases, $plan, $counter, ['carrier' => $carrier, 'receiver' => $receiver, 'creator' => $creator, 'defender' => $marker]);
    }

    /**
     * Chemistry [X22]: a side that knows itself (85 and up) passes better in the build-up, breaks better on the
     * counter and covers better at its box, up to +7% on each of those phases; one that does not (under 50)
     * misplaces passes and leaves gaps. It moves the odds of a phase,
     * never a player's ability. A side without a reading (the simulator) is neutral.
     */
    private function chemistry(string $side): int
    {
        $chem = $this->s['teams'][$side]['chem'] ?? null;
        if ($chem === null) {
            return 0;
        }
        [$from, $to] = $this->eng['chemistry_high_bp'];
        $high = (int) $this->eng['chemistry_high'];
        $low = (int) $this->eng['chemistry_low'];

        return match (true) {
            $chem >= $high => $from + intdiv(($chem - $high) * ($to - $from), max(1, 100 - $high)),
            $chem < $low => -intdiv(($low - $chem) * (int) $this->eng['chemistry_low_bp'], max(1, $low)),
            default => 0,
        };
    }

    /**
     * A bought referee [X28] leans to the side that paid: its fouls are carded less, its opponent's more, and a foul
     * on it at the box is a penalty more often. In basis points of the usual call; 10000 when nobody paid.
     */
    private function leaning(string $side, string $call): int
    {
        $other = $side === 'home' ? 'away' : 'home';
        if ($call === 'penalty') {
            return empty($this->s['teams'][$side]['bribed']) ? 10000 : (int) $this->eng['bribe_penalty_bp'];
        }
        if (! empty($this->s['teams'][$side]['bribed'])) {
            return (int) $this->eng['bribe_own_card_bp'];
        }

        return empty($this->s['teams'][$other]['bribed']) ? 10000 : (int) $this->eng['bribe_rival_card_bp'];
    }

    /** Morale [X25]: a side up (over 50) pushes on and creates more, one down hesitates. None measured: neutral. */
    private function morale(string $side): int
    {
        $morale = $this->s['teams'][$side]['morale'] ?? null;

        return $morale === null ? 0 : ($morale - 50) * (int) $this->eng['morale_bp'];
    }

    private function planKey(string $plan): string
    {
        return ['long' => 'long_balls', 'shots' => 'long_shots'][$plan] ?? $plan;
    }

    /** Positioning: each line is stronger in one role and weaker in another (PLAN 2.14). */
    private function posMod(array $t, string $phase): int
    {
        $mods = [
            'att' => ['back' => ['press' => 120, 'create' => -100], 'only' => ['create' => 120, 'press' => -150]],
            'mid' => ['def' => ['hold' => 120, 'progress' => -100], 'push' => ['progress' => 120, 'hold' => -120]],
            'def' => ['fullbacks' => ['progress' => 100, 'hold' => -100], 'mid' => ['build' => 100, 'hold' => -80]],
        ];
        $total = 0;
        foreach (['att', 'mid', 'def'] as $line) {
            $total += $mods[$line][$t[$line]][$phase] ?? 0;
        }

        return $total;
    }

    /**
     * Marking [Sprint 39 E5]: the zone holds while the back line outnumbers the forwards, and is stretched when it does
     * not; man to man pays when the defenders are as many as the forwards and quicker and stronger than them, and is
     * beaten one on one when they are not.
     */
    private function markingMod(array $td, array $attTeam): int
    {
        $def = $attTeam['side'] === 'home' ? 'away' : 'home';
        $atk = $attTeam['side'];
        $backs = $this->count($def, 'def');
        $forwards = $this->count($atk, 'att');
        $m = $this->eng['marking_cp'];
        if ($td['marking'] !== 'man') {
            return $backs > $forwards ? 0 : (int) $m['zone_outnumbered'];
        }
        $stronger = $this->lineAttr($def, 'def', 'def') + $this->lineAttr($def, 'def', 'pac') > $this->lineAttr($atk, 'att', 'dri') + $this->lineAttr($atk, 'att', 'pac');

        return $stronger && $backs >= $forwards ? (int) $m['man_fit'] : ($stronger ? 0 : (int) $m['man_beaten']);
    }

    /** Players on the pitch in a line (where they stand, not where they come from). */
    private function count(string $side, string $line): int
    {
        return count(array_filter($this->s['teams'][$side]['players'], fn ($p) => $p['on'] && $p['slot_line'] === $line));
    }

    /**
     * [Sprint 39 E4] A plan with the formation built for it (the owner's simulation file): three up for the wings, four
     * in midfield and two up for passing, five in midfield for long shots, five at the back for counters, four up for
     * long balls. A back three suits the wings and passing nearly as well. And the plans that clash with a formation
     * (long shots with three up, wings with one, passing or long balls with a crowded midfield skipped, passing with
     * five at the back). In basis points of the progress and the chance, never the players.
     */
    private function synergy(string $side, string $plan): int
    {
        $d = $this->count($side, 'def');
        $m = $this->count($side, 'mid');
        $a = $this->count($side, 'att');
        $fit = match ($plan) {
            'wings' => $a >= 3 ? 'fit' : ($d === 3 ? 'near' : ($a <= 1 ? 'clash' : null)),
            'passing' => $m === 4 && $a === 2 ? 'fit' : ($d === 3 ? 'near' : ($d >= 5 ? 'clash' : null)),
            'shots' => $m >= 5 ? 'fit' : ($a >= 3 ? 'clash' : null),
            'counter' => $d >= 5 ? 'fit' : null,
            'long' => $a >= 4 ? 'fit' : ($m >= 4 && $a === 2 ? 'clash' : null),
            default => null,
        };

        return $fit === null ? 0 : (int) $this->eng['synergy_bp'][$fit];
    }

    /**
     * [Sprint 39 E4] The golden triangle: settings that pull a side apart leave gaps for the other's progress. Pressing
     * and attacking style far apart split the lines; a back five pushed into a high press and an all-out attack opens;
     * a back three sitting deep gives the space it cannot cover.
     */
    private function gaps(string $side): int
    {
        $t = $this->s['teams'][$side]['tactics'];
        $g = $this->eng['gaps'];
        $bp = max(0, abs($t['pressing'] - $t['style']) - (int) $g['spread']) * (int) $g['per_point_bp'];
        $backs = $this->count($side, 'def');
        if ($backs >= 5 && $t['pressing'] >= 75 && $t['style'] >= 75) {
            $bp += (int) $g['five_open_bp'];
        }
        if ($backs <= 3 && $t['pressing'] < 40) {
            $bp += (int) $g['three_deep_bp'];
        }

        return min((int) $g['max_bp'], $bp);
    }

    /** [Sprint 39 E4] Counters need space: a counter side pressing high wins the ball where there is none to run into. */
    private function counterPlan(array $t, int $bp): int
    {
        $over = max(0, $t['pressing'] - (int) $this->eng['counter_press_from']);

        return intdiv($bp * max(0, 100 - $over * 3), 100);
    }

    private function lineAttr(string $side, string $line, string $attr): int
    {
        $values = [];
        foreach ($this->s['teams'][$side]['players'] as $p) {
            if ($p['on'] && $p['slot_line'] === $line) {
                $values[] = $p['a'][$attr];
            }
        }

        return $values ? intdiv(array_sum($values), count($values)) : 50;
    }

    /**
     * A defender beaten in a duel may foul (docs/ENGINE.md 6.1): more likely
     * with harder tackling, a bigger margin and tired legs. Cards follow from
     * the foul, scaled by the referee.
     */
    private function foul(string $def, string $atk, int $fouler, int $victim, int $margin, string $where, array $phases, string $plan, bool $counter, string $quality = ''): bool
    {
        $td = $this->s['teams'][$def]['tactics'];
        $level = $td['tackling'];
        $tired = 10000 - $this->avgFitness($def);
        $p = (int) $this->eng['foul_bp'][$level] + intdiv(max(0, $margin), 4) + intdiv($tired, 12);
        if (! $this->rng->chance($p)) {
            return false;
        }

        $this->stat($def, 'fouls');
        $this->rate($def, $fouler, -5, 'fouls');
        // [Sprint 39 E3] A side down in morale gives penalties away more easily.
        $defMorale = $this->s['teams'][$def]['morale'] ?? 50;
        $share = intdiv((int) $this->eng['penalty_share_bp'] * (10000 + max(0, 50 - $defMorale) * (int) $this->eng['morale_penalty_bp']), 10000);
        $penalty = $where === 'create' && $this->rng->chance(intdiv($share * $this->leaning($atk, 'penalty'), 10000));
        // A foul at the box always gives a free kick in shooting range, further out only sometimes;
        // otherwise the attackers take it quickly and the attack goes on, so fouling never stops an attack for free.
        $setPiece = $penalty || $where === 'create' || ($where === 'progress' && $this->rng->chance((int) $this->eng['progress_free_kick_bp']));
        if ($setPiece) {
            $this->attackEvent($atk, $plan, $counter, $phases, $penalty ? 'penalty' : 'foul', ['carrier' => $victim, 'defender' => $fouler]);
        }
        $this->event('foul', $def, ['player' => $fouler, 'victim' => $victim, 'penalty' => $penalty]);

        $ref = intdiv((int) $this->eng['referee_bp'][$this->s['referee']] * $this->leaning($def, 'card'), 10000);
        if ($where === 'create' && $quality === 'big' && $this->rng->chance(intdiv((int) $this->eng['dogso_red_bp'] * $ref, 10000))) {
            $this->card($def, $fouler, 'red');
        } elseif ($this->rng->chance(intdiv((int) $this->eng['card_bp'][$level] * $ref, 10000))) {
            $this->card($def, $fouler, 'yellow');
        }

        // Tired legs break [X21]: under the tired line, the victim is injured three times as often.
        $chance = (int) $this->eng['injury_bp'][$level];
        if ($this->fitOf($atk, $victim) < (int) ($this->eng['tired_fit'] ?? 0)) {
            $chance = intdiv($chance * (int) $this->eng['tired_injury_bp'], 10000);
        }
        $injured = $this->rng->chance($chance);
        if ($injured) {
            $this->injure($atk, $victim);
        }

        if (! $setPiece) {
            if (! $injured) {
                return false;
            }
            // Play stops for the injured player: the attack ends here.
            $this->attackEvent($atk, $plan, $counter, $phases, 'foul', ['carrier' => $victim, 'defender' => $fouler]);

            return true;
        }
        $kind = $penalty ? 'penalty' : 'free_kick';
        $taker = $this->firstOn($atk, $this->s['teams'][$atk]['takers'][$kind] ?? 0) ?? $victim;
        $this->setPiece($atk, $taker, $kind);

        return true;
    }

    /** An ordinary foul in a quiet minute: harder tacklers and pressers commit more, cards are rarer. */
    private function midfieldFoul(): void
    {
        $weight = fn ($t) => 10 + $t['tackling'] * 6 + intdiv($t['pressing'], 10);
        $side = (string) $this->rng->weighted([
            'home' => $weight($this->s['teams']['home']['tactics']),
            'away' => $weight($this->s['teams']['away']['tactics']),
        ]);
        $other = $side === 'home' ? 'away' : 'home';
        $fouler = $this->pickPlayer($side, ['mid' => 3, 'def' => 2, 'att' => 1], 'sta');
        $victim = $this->pickPlayer($other, ['mid' => 3, 'att' => 2, 'def' => 1], 'dri');
        $this->stat($side, 'fouls');
        $this->rate($side, $fouler, -3, 'fouls');
        $this->event('foul', $side, ['player' => $fouler, 'victim' => $victim, 'penalty' => false]);
        $level = $this->s['teams'][$side]['tactics']['tackling'];
        $ref = intdiv((int) $this->eng['referee_bp'][$this->s['referee']] * $this->leaning($side, 'card'), 10000);
        if ($this->rng->chance(intdiv((int) $this->eng['card_bp'][$level] * $ref * (int) $this->eng['midfield_card_pct'], 1000000))) {
            $this->card($side, $fouler, 'yellow');
        }
    }

    private function shot(string $atk, int $shooterId, string $quality, array $phases, string $plan, bool $counter, array $who): void
    {
        $def = $atk === 'home' ? 'away' : 'home';
        $this->danger = $atk === 'home' ? 4 : -4;
        $shooter = $this->player($atk, $shooterId);
        $keeper = $this->keeper($def);
        $mix = $quality === 'header' ? 'head' : 'shoot';
        $shot = Ability::player($shooter, $mix);
        $minute = $this->minuteLabel()[0];
        $shot += $minute > 70 ? ($minute - 70) * (int) $this->eng['late_lapse_cp_per_minute'] : 0;
        $save = $keeper ? Ability::player($keeper, 'keep') : 3000;

        $base = (int) $this->eng['goal_base_bp'][$quality];
        // [Sprint 39 E3] Morale up finishes the chances; morale down misses them.
        $moraleNow = $this->s['teams'][$atk]['morale'] ?? null;
        $base += $moraleNow === null ? 0 : ($moraleNow - 50) * (int) $this->eng['morale_finish_bp'];
        $goalP = max(150, min(8500, $base + intdiv(($shot - $save) * (int) $this->eng['goal_slope_bp'], 100)));
        $this->stat($atk, 'shots');
        $this->stat($atk, 'xg', $goalP);
        if ($quality === 'big') {
            $this->stat($atk, 'big_chances');
        }
        $this->rate($atk, $shooterId, 2, 'shots');
        $phases[] = ['n' => 'shot', 'ok' => true, 'p' => $goalP];
        $who['shooter'] = $shooterId;
        $who['keeper'] = $keeper['id'] ?? 0;

        if ($this->rng->chance($goalP)) {
            $this->goal($atk, $shooterId, $who['creator'] ?? $who['receiver'] ?? 0);
            $this->attackEvent($atk, $plan, $counter, $phases, 'goal', $who, $quality);

            return;
        }

        if ($this->rng->chance((int) $this->eng['on_target_bp'])) {
            $this->stat($atk, 'on_target');
            $this->stat($def, 'saves');
            $this->rate($atk, $shooterId, 8, 'on_target');
            if ($keeper) {
                $this->rate($def, $keeper['id'], 15, 'saves');
            }
            $corner = $this->rng->chance((int) $this->eng['corner_after_save_bp']);
            $this->attackEvent($atk, $plan, $counter, $phases, 'saved', $who, $quality);
            if ($corner) {
                $this->corner($atk);
            }

            return;
        }

        $blocked = $this->rng->chance(3000);
        $this->attackEvent($atk, $plan, $counter, $phases, $blocked ? 'blocked' : 'missed', $who, $quality);
        if ($blocked && $this->rng->chance(4000)) {
            $this->corner($atk);
        }
    }

    private function corner(string $atk): void
    {
        $def = $atk === 'home' ? 'away' : 'home';
        $this->stat($atk, 'corners');
        $taker = $this->firstOn($atk, $this->s['teams'][$atk]['takers']['corner'] ?? 0);
        $header = $this->bestOn($atk, 'head', true);
        $marker = $this->bestOn($def, 'def', true);
        if (! $header || ! $marker) {
            return;
        }
        $a = Ability::player($this->player($atk, $header), 'head') + ($taker ? ($this->player($atk, $taker)['a']['cross'] - 60) * 10 : 0);
        $d = Ability::player($this->player($def, $marker), 'mark');
        $r = $this->phase('header', $a, $d);
        $this->event('corner', $atk, ['taker' => $taker, 'won' => $r['ok']]);
        if ($r['ok']) {
            $this->shot($atk, $header, 'header', [['n' => 'corner', 'ok' => true, 'p' => $r['p']]], 'corner', false,
                ['carrier' => $taker ?? $header, 'creator' => $taker ?? 0, 'defender' => $marker]);
        }
    }

    private function setPiece(string $atk, int $taker, string $kind): void
    {
        $def = $atk === 'home' ? 'away' : 'home';
        $keeper = $this->keeper($def);
        $p = $this->player($atk, $taker);
        $skill = $kind === 'penalty' ? $p['a']['pen'] : $p['a']['fk'];
        $base = $kind === 'penalty' ? (int) $this->eng['penalty_goal_bp'] : (int) $this->eng['free_kick_goal_bp'];
        $goalP = max(100, min(9200, $base + ($skill - ($keeper['a']['gk'] ?? 50)) * 25));
        $this->stat($atk, 'shots');
        $this->stat($atk, 'xg', $goalP);
        $this->rate($atk, $taker, 2, 'shots');
        $scored = $this->rng->chance($goalP);
        $this->event($kind, $atk, ['taker' => $taker, 'keeper' => $keeper['id'] ?? 0, 'scored' => $scored]);
        if ($scored) {
            $this->goal($atk, $taker, 0, $kind);
        } elseif ($this->rng->chance(5500)) {
            $this->stat($atk, 'on_target');
            $this->stat($def, 'saves');
        }
    }

    private function goal(string $side, int $scorer, int $assist, string $kind = 'open'): void
    {
        $other = $side === 'home' ? 'away' : 'home';
        $this->s['score'][$side]++;
        $this->stat($side, 'goals');
        $this->rate($side, $scorer, 100, 'goals');
        if ($assist && $assist !== $scorer) {
            $this->rate($side, $assist, 60, 'assists');
        }
        foreach ($this->s['teams'][$other]['players'] as $p) {
            if ($p['on'] && in_array($p['slot_line'], ['gk', 'def'], true)) {
                $this->rate($other, $p['id'], -15);
            }
        }
        $this->danger = $side === 'home' ? 5 : -5;
        $this->periodEvents++;
        $this->event('goal', $side, ['scorer' => $scorer, 'assist' => $assist !== $scorer ? $assist : 0, 'kind' => $kind, 'score' => $this->s['score']]);
    }

    private function card(string $side, int $playerId, string $color): void
    {
        $i = $this->index($side, $playerId);
        if ($i === null) {
            return;
        }
        $p = &$this->s['teams'][$side]['players'][$i];
        // A booked player plays carefully and referees think twice about a second yellow.
        if ($color === 'yellow' && $p['yc'] === 1 && $this->rng->chance((int) $this->eng['second_yellow_spare_bp'])) {
            return;
        }
        if ($color === 'yellow') {
            $p['yc']++;
            $this->stat($side, 'yellow');
            $p['st']['r'] -= 30;
            $this->event('card', $side, ['player' => $playerId, 'color' => 'yellow']);
            if ($p['yc'] < 2) {
                return;
            }
        }
        $this->stat($side, 'red');
        $p['st']['r'] -= 150;
        $p['on'] = false;
        $p['out'] = 'red';
        $this->s['teams'][$side]['missing']++;
        $this->periodEvents++;
        $this->event('card', $side, ['player' => $playerId, 'color' => 'red', 'second_yellow' => $color === 'yellow']);
    }

    /** An injured player leaves; the best bench player for his line replaces him if a sub is left. */
    private function injure(string $side, int $playerId): void
    {
        $i = $this->index($side, $playerId);
        if ($i === null || ! $this->s['teams'][$side]['players'][$i]['on']) {
            return;
        }
        $team = &$this->s['teams'][$side];
        $leaving = $team['players'][$i];
        $team['players'][$i]['on'] = false;
        $team['players'][$i]['out'] = 'injury';
        $this->periodEvents++;
        $this->event('injury', $side, ['player' => $playerId]);

        if ($team['subs_used'] >= $team['subs_max']) {
            $team['missing']++;

            return;
        }
        // [UP17] The emergency substitution: play stops, and the coach picks who comes on before the next minute;
        // his order (or, without one, the best on the bench) goes in at its start (fillInjured). A match made before
        // has no emergency_sub in its snapshot and replaces him here, as it did.
        if (! empty($this->cfg['emergency_sub'])) {
            $team['missing']++;
            $team['pending_injury'] = $playerId;

            return;
        }
        $this->replace($side, $playerId);
    }

    /** The best bench player for the injured one's line takes his place, if there is one. */
    private function replace(string $side, int $playerId): void
    {
        $team = &$this->s['teams'][$side];
        $leaving = $team['players'][$this->index($side, $playerId)];
        $best = null;
        foreach ($team['players'] as $j => $p) {
            if (! $p['on'] && $p['out'] === '' && $p['slot'] === null) {
                $score = $p['a']['ovr'] * 10 + ($p['line'] === $leaving['slot_line'] ? 1000 : 0);
                if ($best === null || $score > $best[0]) {
                    $best = [$score, $j];
                }
            }
        }
        if ($best === null) {
            $team['missing']++;

            return;
        }
        $j = $best[1];
        $team['players'][$j]['on'] = true;
        $team['players'][$j]['slot'] = $leaving['slot'];
        $team['players'][$j]['slot_line'] = $leaving['slot_line'];
        $team['subs_used']++;
        $this->event('sub', $side, ['out' => $playerId, 'in' => $team['players'][$j]['id'], 'reason' => 'injury']);
    }

    /** [UP17] Before the minute: an injured player still waiting for his replacement gets the bench's best. */
    private function fillInjured(): void
    {
        foreach (['home', 'away'] as $side) {
            $pending = $this->s['teams'][$side]['pending_injury'] ?? null;
            if ($pending === null) {
                continue;
            }
            unset($this->s['teams'][$side]['pending_injury']);
            $this->s['teams'][$side]['missing']--;
            $this->replace($side, (int) $pending);
        }
    }

    private function fatigue(): void
    {
        foreach (['home', 'away'] as $side) {
            $team = &$this->s['teams'][$side];
            $t = $team['tactics'];
            $drain = (int) $this->eng['fitness_drain_base']
                + intdiv($t['pressing'] * (int) $this->eng['fitness_drain_pressing_max'], 100)
                + intdiv($t['tempo'] * (int) $this->eng['fitness_drain_tempo_max'], 100);
            if ($team['missing'] > 0) {
                $drain = intdiv($drain * (int) $this->eng['red_card_drain_bp'], 10000);
            }
            foreach ($team['players'] as &$p) {
                if (! $p['on']) {
                    continue;
                }
                $own = $p['line'] === 'gk' ? intdiv($drain, 2) : intdiv($drain * (130 - $p['a']['sta']), 60);
                $p['fit'] = max(0, $p['fit'] - $own);
            }
            unset($p);
        }
    }

    private function shootout(): void
    {
        $kicks = [];
        $score = ['home' => 0, 'away' => 0];
        $order = [];
        foreach (['home', 'away'] as $side) {
            $takers = array_values(array_filter($this->s['teams'][$side]['players'], fn ($p) => $p['on']));
            usort($takers, fn ($a, $b) => $b['a']['pen'] <=> $a['a']['pen'] ?: $a['id'] <=> $b['id']);
            $order[$side] = $takers;
        }
        for ($round = 0; $round < 30; $round++) {
            foreach (['home', 'away'] as $side) {
                $other = $side === 'home' ? 'away' : 'home';
                $taker = $order[$side][$round % max(1, count($order[$side]))];
                $keeper = $this->keeper($other);
                $p = max(4000, min(9000, 7500 + ($taker['a']['pen'] - ($keeper['a']['gk'] ?? 50)) * 20));
                $in = $this->rng->chance($p);
                $score[$side] += $in ? 1 : 0;
                $kicks[] = ['team' => $side, 'taker' => $taker['id'], 'scored' => $in];
            }
            $left = max(0, 4 - $round);
            if ($round < 5 && (abs($score['home'] - $score['away']) > $left)) {
                break;
            }
            if ($round >= 4 && $score['home'] !== $score['away']) {
                break;
            }
        }
        $this->s['shootout'] = $score;
        $this->event('shootout', null, ['kicks' => $kicks, 'score' => $score]);
        $this->finish();
    }

    // -------------------------------------------------------------- helpers

    private function attackEvent(string $side, string $plan, bool $counter, array $phases, string $result, array $who, string $quality = ''): void
    {
        $lane = ['left', 'center', 'right'][$plan === 'wings' ? ($this->rng->chance(5000) ? 0 : 2) : $this->rng->int(3)];
        $this->event('attack', $side, array_filter([
            'plan' => $plan, 'counter' => $counter, 'phases' => $phases, 'result' => $result, 'lane' => $lane,
            'quality' => $quality, 'carrier' => $who['carrier'] ?? 0, 'receiver' => $who['receiver'] ?? 0,
            'creator' => $who['creator'] ?? 0, 'shooter' => $who['shooter'] ?? 0, 'defender' => $who['defender'] ?? 0,
            'keeper' => $who['keeper'] ?? 0,
        ], fn ($v) => $v !== '' && $v !== 0) + ['counter' => $counter]);
    }

    private function event(string $type, ?string $team, array $data = []): void
    {
        $this->events[] = ['type' => $type, 'team' => $team] + $data;
    }

    private function stat(string $side, string $key, int $by = 1): void
    {
        $this->s['teams'][$side]['stats'][$key] += $by;
    }

    private function third(string $atk, int $phaseIndex): void
    {
        $this->s['thirds'][$atk === 'home' ? $phaseIndex : 2 - $phaseIndex]++;
    }

    private function rate(string $side, int $id, int $points, ?string $stat = null): void
    {
        $i = $this->index($side, $id);
        if ($i === null) {
            return;
        }
        $p = &$this->s['teams'][$side]['players'][$i];
        $p['st']['r'] = max(300, min(1000, $p['st']['r'] + $points));
        $p['st']['touches']++;
        if ($stat !== null) {
            $p['st'][$stat]++;
        }
    }

    private function index(string $side, int $id): ?int
    {
        foreach ($this->s['teams'][$side]['players'] as $i => $p) {
            if ($p['id'] === $id) {
                return $i;
            }
        }

        return null;
    }

    private function player(string $side, int $id): ?array
    {
        $i = $this->index($side, $id);

        return $i === null ? null : $this->s['teams'][$side]['players'][$i];
    }

    private function firstOn(string $side, int $id): ?int
    {
        $p = $this->player($side, $id);
        if ($p && $p['on']) {
            return $id;
        }

        return $this->bestOn($side, 'pas', true);
    }

    private function bestOn(string $side, string $attr, bool $field = false): ?int
    {
        $best = null;
        foreach ($this->s['teams'][$side]['players'] as $p) {
            if ($p['on'] && (! $field || $p['slot_line'] !== 'gk') && ($best === null || $p['a'][$attr] > $best['a'][$attr])) {
                $best = $p;
            }
        }

        return $best['id'] ?? null;
    }

    private function keeper(string $side): ?array
    {
        foreach ($this->s['teams'][$side]['players'] as $p) {
            if ($p['on'] && $p['slot_line'] === 'gk') {
                return $p;
            }
        }
        foreach ($this->s['teams'][$side]['players'] as $p) {
            if ($p['on']) {
                return $p;
            }
        }

        return null;
    }

    /** One player's fitness, in hundredths of a per cent (100% when not found). */
    private function fitOf(string $side, int $playerId): int
    {
        foreach ($this->s['teams'][$side]['players'] as $p) {
            if ($p['id'] === $playerId) {
                return $p['fit'];
            }
        }

        return 10000;
    }

    private function avgFitness(string $side): int
    {
        $sum = 0;
        $n = 0;
        foreach ($this->s['teams'][$side]['players'] as $p) {
            if ($p['on']) {
                $sum += $p['fit'];
                $n++;
            }
        }

        return $n ? intdiv($sum, $n) : 10000;
    }

    /** A player from the given lines, weighted by line and by one attribute. */
    private function pickPlayer(string $side, array $lineWeights, string $attr, array $exclude = []): int
    {
        $weights = [];
        foreach ($this->s['teams'][$side]['players'] as $p) {
            if (! $p['on'] || in_array($p['id'], $exclude, true)) {
                continue;
            }
            $w = $lineWeights[$p['slot_line']] ?? 0;
            if ($w > 0) {
                $weights[$p['id']] = $w * max(1, $p['a'][$attr] - 30);
            }
        }
        if (! $weights) {
            foreach ($this->s['teams'][$side]['players'] as $p) {
                if ($p['on']) {
                    $weights[$p['id']] = 1;
                }
            }
        }

        return (int) $this->rng->weighted($weights);
    }
}
