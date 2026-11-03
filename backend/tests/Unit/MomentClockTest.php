<?php

namespace Tests\Unit;

use App\Characters\Mood;
use App\Engine\MatchSetup;
use App\Simulator\MomentClock;
use App\Simulator\Runner;
use App\Simulator\Voice;
use Tests\TestCase;

class MomentClockTest extends TestCase
{
    private array $match = ['tick_ms' => 3000, 'moment_ms' => [
        'quiet' => 900, 'attack' => 1600, 'stoppage' => 2400, 'shootout' => 3000, 'offside' => 6400, 'miss' => 7000, 'save' => 6400,
        'corner' => 5600, 'goal' => 12800, 'yellow' => 6800, 'red' => 9000, 'free_kick' => 8600, 'free_kick_goal' => 9400,
        'penalty' => 10000, 'penalty_goal' => 10600, 'sub' => 5600, 'injury' => 6000,
    ]];

    public function test_each_minute_gets_the_shot_of_its_most_important_event(): void
    {
        $attack = fn ($result) => ['type' => 'attack', 'team' => 'home', 'result' => $result];
        $cases = [
            'quiet' => [],
            'attack' => [$attack('lost')],
            'miss' => [$attack('blocked')],
            'save' => [$attack('saved')],
            'offside' => [$attack('offside')],
            'goal' => [['type' => 'goal', 'team' => 'home', 'kind' => 'open'], $attack('goal'), ['type' => 'sub', 'team' => 'away']],
            'penalty' => [$attack('penalty'), ['type' => 'penalty', 'team' => 'home', 'scored' => false]],
            'red' => [$attack('foul'), ['type' => 'foul', 'team' => 'away'], ['type' => 'card', 'team' => 'away', 'color' => 'red']],
            'corner' => [['type' => 'corner', 'team' => 'home']],
            'sub' => [['type' => 'sub', 'team' => 'home']],
            'stoppage' => [['type' => 'stoppage', 'added' => 3]],
            'coach' => [['type' => 'action', 'team' => 'home', 'action' => ['type' => 'tactics', 'tactics' => ['pressing' => 80]]], $attack('lost')],
            'whistle' => [['type' => 'period', 'team' => null, 'name' => 'halftime']],
        ];
        foreach ($cases as $kind => $events) {
            $this->assertSame($kind, MomentClock::kind($events), $kind);
        }
    }

    public function test_durations_come_from_the_config_and_scored_set_pieces_play_longer(): void
    {
        $this->assertSame(['kind' => 'quiet', 'ms' => 900], MomentClock::moment([], $this->match));
        // A sub ordered by the coach plays the sub shot, not the coach's.
        $this->assertSame('sub', MomentClock::kind([['type' => 'action', 'team' => 'home', 'action' => ['type' => 'sub']], ['type' => 'sub', 'team' => 'home']]));
        $pen = [['type' => 'penalty', 'team' => 'home', 'scored' => true], ['type' => 'goal', 'team' => 'home', 'kind' => 'penalty']];
        $this->assertSame(['kind' => 'penalty', 'ms' => 10600], MomentClock::moment($pen, $this->match));
        // The pause after a scene is added to it, not to the quiet minutes.
        $paused = $this->match + ['scene_gap_ms' => 1500];
        $this->assertSame(10600 + 1500, MomentClock::moment($pen, $paused)['ms']);
        $this->assertSame(900, MomentClock::moment([], $paused)['ms']);
        // Matches created before the table existed keep the fixed minute.
        $this->assertSame(3000, MomentClock::moment([], ['tick_ms' => 3000])['ms']);
    }

    /** [X35] The broadcast's pace: 18 minutes of football a real minute, extra time and the shootout half a minute. */
    public function test_the_broadcast_plays_every_minute_at_a_fixed_pace(): void
    {
        $match = $this->match + ['minute_ms' => 3333, 'extra_minute_ms' => 2000, 'shootout_ms' => 30000];
        $goal = [['type' => 'goal', 'team' => 'home', 'kind' => 'open']];
        $this->assertSame(['kind' => 'quiet', 'ms' => 3333], MomentClock::moment([], $match, 1));
        $this->assertSame(['kind' => 'goal', 'ms' => 3333], MomentClock::moment($goal, $match, 2));
        // A half of 45 minutes is two and a half real minutes; an extra-time half (15) half a minute.
        $this->assertSame(150, intdiv(45 * MomentClock::moment([], $match, 1)['ms'] + 999, 1000));
        $this->assertSame(30000, 15 * MomentClock::moment($goal, $match, 3)['ms']);
        $this->assertSame(30000, MomentClock::moment([['type' => 'shootout', 'team' => null]], $match, 5)['ms']);
    }

    /** [X41] The broadcast as on TV: a small chance is only its card, a big moment its real length. */
    public function test_the_broadcast_gives_the_big_moments_their_length_and_the_small_ones_a_card(): void
    {
        $match = $this->match + ['minute_ms' => 3333, 'extra_minute_ms' => 2000, 'shootout_ms' => 30000, 'broadcast_ms' => config('game.match.broadcast_ms')];
        $shot = fn (string $result, string $quality) => [['type' => 'attack', 'team' => 'home', 'result' => $result, 'quality' => $quality]];
        $this->assertSame(['kind' => 'goal', 'ms' => 20000], MomentClock::moment([['type' => 'goal', 'team' => 'home', 'kind' => 'open']], $match));
        $this->assertSame(['kind' => 'miss', 'ms' => (int) config('game.match.broadcast_ms.miss')], MomentClock::moment($shot('missed', 'big'), $match));
        $this->assertSame(['kind' => 'save', 'ms' => (int) config('game.match.broadcast_ms.save')], array_intersect_key(MomentClock::moment($shot('saved', 'header'), $match), ['kind' => 1, 'ms' => 1]));
        foreach ([$shot('blocked', 'big'), $shot('missed', 'long'), $shot('saved', 'normal'), $shot('offside', '')] as $events) {
            // [Sprint 42 F] Unless it is told as a gag (a clearance off the line, the offside trap): a short scene.
            $m = MomentClock::moment($events, $match);
            $this->assertTrue(($m['brief'] ?? false) || in_array($m['drama'] ?? null, ['clearance', 'trap'], true));
        }
        $this->assertTrue(MomentClock::moment([['type' => 'free_kick', 'team' => 'home', 'taker' => 1]], $match)['brief'] ?? false);
        $this->assertArrayNotHasKey('brief', MomentClock::moment([['type' => 'free_kick', 'team' => 'home', 'taker' => 1, 'keeper' => 2]], $match));
        $this->assertSame(30000, MomentClock::moment([['type' => 'shootout', 'team' => null]], $match, 5)['ms']);
    }

    /** [X94] The highlights broadcast: the small moments are a card, a goal and a real chance their scene. */
    public function test_the_highlights_broadcast_plays_only_the_big_moments(): void
    {
        $match = $this->match + ['minute_ms' => 3333, 'extra_minute_ms' => 2000, 'shootout_ms' => 30000,
            'broadcast_ms' => config('game.match.broadcast_ms'), 'broadcast_brief' => config('game.match.broadcast_brief')];
        foreach ([[['type' => 'corner', 'team' => 'home', 'taker' => 1]], [['type' => 'free_kick', 'team' => 'home', 'taker' => 1, 'keeper' => 2]]] as $events) {
            $this->assertTrue(MomentClock::moment($events, $match)['brief'] ?? false, json_encode($events));
        }
        foreach ([[['type' => 'goal', 'team' => 'home', 'kind' => 'open']], [['type' => 'card', 'team' => 'home', 'player' => 1, 'color' => 'red']],
            [['type' => 'free_kick', 'team' => 'home', 'taker' => 1, 'keeper' => 2], ['type' => 'goal', 'team' => 'home', 'kind' => 'free_kick']],
            [['type' => 'penalty', 'team' => 'home', 'taker' => 1]], [['type' => 'attack', 'team' => 'home', 'result' => 'saved', 'quality' => 'big']],
            // [Sprint 42] The owner's cartoon clips: a yellow card, a sub and an injury play their scene again.
            [['type' => 'card', 'team' => 'home', 'player' => 1, 'color' => 'yellow']], [['type' => 'sub', 'team' => 'home', 'in' => 1, 'out' => 2]],
            [['type' => 'injury', 'team' => 'home', 'player' => 1]]] as $events) {
            $this->assertArrayNotHasKey('brief', MomentClock::moment($events, $match), json_encode($events));
        }
        // A quiet minute runs by in a second.
        $this->assertSame(1000, MomentClock::moment([], $match)['ms']);
    }

    /** [X94] The owner's length: a half about two real minutes (three and a half before, X41). */
    public function test_a_broadcast_half_lasts_about_two_minutes(): void
    {
        $positions = ['GK', 'GK', 'RB', 'CB', 'CB', 'LB', 'CB', 'CDM', 'CM', 'CM', 'CAM', 'RM', 'LM', 'RW', 'LW', 'ST', 'ST', 'CM'];
        $lines = ['GK' => 'gk', 'RB' => 'def', 'CB' => 'def', 'LB' => 'def', 'CDM' => 'mid', 'CM' => 'mid', 'CAM' => 'mid',
            'RM' => 'mid', 'LM' => 'mid', 'RW' => 'att', 'LW' => 'att', 'ST' => 'att'];
        $squad = fn (int $base, int $ovr) => array_map(fn ($pos, $i) => [
            'id' => $base + $i, 'name' => "P{$base}x{$i}", 'position' => $pos, 'line' => $lines[$pos], 'age' => 20 + $i,
            'overall' => $ovr - intdiv($i, 3), 'penalties' => 70, 'free_kick' => 65, 'crossing' => 65, 'heading' => 65,
        ], $positions, array_keys($positions));
        $club = fn ($id) => ['id' => $id, 'name' => "C{$id}", 'code' => 'C'.$id, 'primary' => '#000000', 'secondary' => '#FFFFFF', 'strength' => 8000];
        $ms = 0;
        $halves = 0;
        foreach ([3, 11, 42, 77] as $seed) {
            $state = MatchSetup::build(['club' => $club(1), 'squad' => $squad(100, 80)], ['club' => $club(2), 'squad' => $squad(200, 78)],
                ['seed' => $seed, 'competition' => 'league'], ['match' => config('game.match'), 'engine' => config('game.engine')]);
            while (! $state['finished']) {
                $state = Runner::tick($state);
                $ms += MomentClock::moment($state['out']['events'], $state['cfg']['match'], (int) ($state['out']['period'] ?? 1))['ms'];
            }
            $halves += 2;
        }
        $half = intdiv($ms, $halves);
        $this->assertGreaterThan(90000, $half);
        $this->assertLessThan(150000, $half);
    }

    /** [Sprint 42 A1] How a card is told (its drama) comes from its players, the same every time, with every telling used. */
    public function test_a_card_has_its_drama_from_the_events(): void
    {
        $card = fn (string $color, int $p, bool $second = false) => [['type' => 'foul', 'team' => 'home', 'player' => $p, 'victim' => 100 + $p, 'penalty' => false],
            ['type' => 'card', 'team' => 'home', 'player' => $p, 'color' => $color] + ($second ? ['second_yellow' => true] : [])];
        $yellows = array_map(fn ($p) => MomentClock::moment($card('yellow', $p), $this->match)['drama'], range(1, 60));
        $reds = array_map(fn ($p) => MomentClock::moment($card('red', $p), $this->match)['drama'], range(1, 60));
        $this->assertEqualsCanonicalizing(['tackle', 'swarm'], array_values(array_unique($yellows)));
        $this->assertEqualsCanonicalizing(['tackle', 'brawl', 'spit'], array_values(array_unique($reds)));
        $this->assertSame($reds, array_map(fn ($p) => MomentClock::moment($card('red', $p), $this->match)['drama'], range(1, 60)));
        // A second yellow is never a fight or a spit: a tackle or a swarm round the referee.
        foreach (range(1, 30) as $p) {
            $this->assertContains(MomentClock::moment($card('red', $p, true), $this->match)['drama'], ['tackle', 'swarm']);
        }
        // Other moments have none.
        $this->assertArrayNotHasKey('drama', MomentClock::moment([['type' => 'goal', 'team' => 'home', 'kind' => 'open']], $this->match));
    }

    /** [Sprint 42 A2] One foul in three is its own scene (a tackle or a dive), only in a match made with its length. */
    public function test_a_foul_is_its_own_scene_in_a_new_match(): void
    {
        $match = $this->match + ['minute_ms' => 3333, 'extra_minute_ms' => 2000, 'shootout_ms' => 30000,
            'broadcast_ms' => config('game.match.broadcast_ms'), 'broadcast_brief' => config('game.match.broadcast_brief')];
        $foul = fn (int $p) => [['type' => 'attack', 'team' => 'away', 'result' => 'foul', 'quality' => 'normal'],
            ['type' => 'foul', 'team' => 'home', 'player' => $p, 'victim' => 200 + $p, 'penalty' => false]];
        $shown = array_filter(range(1, 60), fn ($p) => MomentClock::moment($foul($p), $match)['kind'] === 'foul');
        $this->assertGreaterThan(10, count($shown));
        $this->assertLessThan(35, count($shown));
        $dramas = array_unique(array_map(fn ($p) => MomentClock::moment($foul($p), $match)['drama'], $shown));
        $this->assertEqualsCanonicalizing(['dive', 'tackle'], array_values($dramas));
        $this->assertSame((int) config('game.match.broadcast_ms.foul'), MomentClock::moment($foul(reset($shown)), $match)['ms']);
        // A penalty foul is the penalty; a match made before keeps its minute as it was (no foul in its lengths).
        $this->assertNotSame('foul', MomentClock::kind([['type' => 'foul', 'team' => 'home', 'player' => reset($shown), 'victim' => 200 + reset($shown), 'penalty' => true]], true));
        $old = $match;
        unset($old['broadcast_ms']['foul']);
        $this->assertNotSame('foul', MomentClock::moment($foul(reset($shown)), $old)['kind']);
    }

    /** [Sprint 42 F] The second set's gags: each from its own events, each used, the small ones a short scene of their own. */
    public function test_the_gags_come_from_the_events(): void
    {
        $match = $this->match + ['minute_ms' => 3333, 'extra_minute_ms' => 2000, 'shootout_ms' => 30000,
            'broadcast_ms' => config('game.match.broadcast_ms'), 'broadcast_brief' => config('game.match.broadcast_brief')];
        $atk = fn (string $result, string $quality, int $p) => ['type' => 'attack', 'team' => 'home', 'result' => $result, 'quality' => $quality, 'shooter' => $p, 'carrier' => $p + 1, 'receiver' => $p, 'defender' => $p + 50, 'lane' => 'center'];
        $goal = fn (string $quality, int $p, ?int $assist) => [$atk('goal', $quality, $p), ['type' => 'goal', 'team' => 'home', 'kind' => 'open', 'scorer' => $p, 'assist' => $assist]];
        $dramas = fn (callable $events) => array_values(array_unique(array_filter(array_map(fn ($p) => MomentClock::moment($events($p), $match)['drama'] ?? null, range(1, 80)))));
        $this->assertEqualsCanonicalizing(['blackout', 'nolook', 'nutmeg'], $dramas(fn ($p) => $goal('big', $p, $p + 3)));
        $this->assertEqualsCanonicalizing(['blackout', 'bicycle'], $dramas(fn ($p) => $goal('header', $p, $p + 3)));
        $this->assertEqualsCanonicalizing(['double'], $dramas(fn ($p) => [$atk('saved', 'big', $p)]));
        $this->assertSame([], $dramas(fn ($p) => [$atk('saved', 'normal', $p)]), 'a small save stays a card');
        $this->assertEqualsCanonicalizing(['clearance'], $dramas(fn ($p) => [$atk('blocked', 'big', $p)]));
        $this->assertEqualsCanonicalizing(['trap'], $dramas(fn ($p) => [$atk('offside', '', $p)]));
        // The gags that were a card are a short scene now, of their own length.
        foreach (range(1, 40) as $p) {
            $m = MomentClock::moment([$atk('offside', '', $p)], $match);
            // (One offside in three is a goal ruled out by VAR, its own scene.)
            if ($m['kind'] === 'var') {
                continue;
            }
            ($m['drama'] ?? null) === 'trap' ? $this->assertSame(['kind' => 'offside', 'ms' => (int) config('game.match.broadcast_ms.trap'), 'drama' => 'trap'], $m) : $this->assertTrue($m['brief']);
        }
        $rant = array_filter(range(1, 40), fn ($p) => (MomentClock::moment([['type' => 'action', 'team' => 'home', 'action' => ['type' => 'tactics', 'tactics' => ['tempo' => $p]]]], $match)['drama'] ?? null) === 'rant');
        $this->assertNotEmpty($rant);
        $this->assertLessThan(40, count($rant));
    }

    /** [Sprint 42 F8] In the rain (the match's seed, as the cartoon draws it), a ball lost can be a slip; never in the dry. */
    public function test_a_slip_only_in_the_rain(): void
    {
        $match = $this->match + ['minute_ms' => 3333, 'extra_minute_ms' => 2000, 'shootout_ms' => 30000,
            'broadcast_ms' => config('game.match.broadcast_ms'), 'broadcast_brief' => config('game.match.broadcast_brief')];
        $lost = fn ($p) => [['type' => 'attack', 'team' => 'home', 'result' => 'lost', 'carrier' => $p, 'defender' => $p + 50]];
        $kinds = fn (int $seed) => array_map(fn ($p) => MomentClock::moment($lost($p), $match, 1, $seed)['kind'], range(1, 60));
        $this->assertTrue(MomentClock::rainy(7));
        $this->assertFalse(MomentClock::rainy(8));
        $wet = array_count_values($kinds(7));
        $this->assertGreaterThan(8, $wet['slip'] ?? 0);
        $this->assertNotContains('slip', $kinds(8));
        $this->assertNotContains('slip', array_map(fn ($p) => MomentClock::moment($lost($p), $match)['kind'], range(1, 60)), 'no seed: no rain');
    }

    /** [Sprint 35 C3] A goal ruled out by VAR: a big chance offside, or one the attackers fouled in; with its reason. */
    public function test_a_goal_ruled_out_by_var(): void
    {
        $attack = fn ($result, $quality = 'big', $receiver = 1) => ['type' => 'attack', 'team' => 'home', 'result' => $result, 'quality' => $quality, 'carrier' => 5, 'receiver' => $receiver, 'lane' => 'center'];
        // One offside in three (by the attack's own players), the same every time.
        $kinds = array_map(fn ($r) => MomentClock::kind([$attack('offside', null, $r)]), range(1, 30));
        $vars = count(array_filter($kinds, fn ($k) => $k === 'var'));
        $this->assertGreaterThan(4, $vars);
        $this->assertLessThan(20, $vars);
        $this->assertSame($kinds, array_map(fn ($r) => MomentClock::kind([$attack('offside', null, $r)]), range(1, 30)));
        $r = array_search('var', $kinds, true) + 1;
        $this->assertSame('offside', MomentClock::varReason([$attack('offside', null, $r)]));
        $foul = [$attack('missed'), ['type' => 'foul', 'team' => 'home', 'penalty' => false]];
        $this->assertSame('var', MomentClock::kind($foul));
        $this->assertSame('foul', MomentClock::varReason($foul));
        $this->assertSame('miss', MomentClock::kind([$attack('missed'), ['type' => 'foul', 'team' => 'away']]), 'the defenders\' foul rules nothing out');
        // A card still has its own scene.
        $this->assertSame('yellow', MomentClock::kind([...$foul, ['type' => 'card', 'team' => 'home', 'color' => 'yellow']]));
        $m = MomentClock::moment($foul, config('game.match'));
        $this->assertSame(['kind' => 'var', 'ms' => (int) config('game.match.broadcast_ms.var'), 'var' => 'foul'], $m);
        $voice = Voice::for($foul, 'var', 3, 10);
        $this->assertSame('var_foul', $voice['line']);
        $moods = Mood::forTick([$attack('offside', null, $r)], ['home' => 0, 'away' => 0], 30);
        $this->assertSame(['home' => 'angry', 'away' => 'joy'], $moods);
    }
}
