<?php

namespace Tests\Feature;

use App\League\FormationBook;
use App\League\TeamSheet;
use App\Models\Club;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** The team sheet: lineup, formations, custom formations and set-piece takers [Sprint 16, PLAN 2.15, 2.16]. */
class TeamSheetTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    private string $url;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner);
        $this->url = "/api/v1/leagues/{$this->league['id']}/team";
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_the_24_formations_keep_within_the_line_limits(): void
    {
        $this->assertCount(24, FormationBook::names());
        foreach (FormationBook::names() as $name) {
            $slots = FormationBook::slots($name);
            $this->assertCount(11, $slots, $name);
            $this->assertSame('gk', $slots[0]['line'], $name);
            $this->assertNull(FormationBook::invalid($slots), $name);
            $this->assertSame(10, array_sum(FormationBook::lines($slots)), $name);
        }
        $this->getJson('/api/v1/data/formations')->assertOk()->assertJsonCount(24, 'formations')
            ->assertJsonPath('formations.0.label', '4-4-2 A')->assertJsonPath('limits.def', [3, 6]);
    }

    public function test_a_new_club_gets_the_automatic_lineup_and_takers(): void
    {
        $team = $this->actingAs($this->owner)->getJson($this->url)->assertOk()->json();
        $this->assertTrue($team['lineup']['auto']);
        $this->assertCount(11, array_filter($team['lineup']['starters']));
        $this->assertCount(7, $team['lineup']['bench']);
        $players = collect($team['players'])->keyBy('id');
        // The goalkeeper's slot has the better keeper, and a keeper sits on the bench.
        $this->assertSame('gk', $players[$team['lineup']['starters'][0]]['line']);
        $this->assertSame('gk', $players[$team['lineup']['bench'][0]]['line']);
        $this->assertSame(11, $players->where('role', 'starter')->count());
        foreach (['captain', 'penalty', 'free_kick', 'corner'] as $role) {
            $this->assertContains($team['takers'][$role]['player_id'], $team['lineup']['starters'], $role);
            $this->assertTrue($team['takers'][$role]['auto']);
        }
        // A player's card has what the design shows.
        $this->assertSame(['pac', 'sho', 'pas', 'dri', 'def', 'phy'], array_keys($players->firstWhere('line', 'att')['attributes']));
        $this->assertArrayHasKey('potential', $players->first());
        $this->actingAs(User::factory()->create())->getJson($this->url)->assertForbidden()->assertJsonPath('message', 'ليس لديك فريق في هذا الدوري.');
    }

    public function test_each_slot_says_which_lines_it_takes(): void
    {
        // [Sprint 59 F6] The screens read the rule from the server instead of keeping their own.
        $team = $this->actingAs($this->owner)->getJson($this->url)->assertOk()->json();
        $this->assertSame(['gk'], $team['lineup']['slots'][0]['allowed']);
        foreach (array_slice($team['lineup']['slots'], 1) as $slot) {
            $this->assertSame(['def', 'mid', 'att'], $slot['allowed']);
        }
        $this->assertSame(['gk'], $this->getJson('/api/v1/data/formations')->json('formations.0.slots.0.allowed'));
        $this->assertSame(['gk'], TeamSheet::allowed('gk'));
        $this->assertSame(['def', 'mid', 'att'], TeamSheet::allowed('mid'));
    }

    public function test_an_injured_player_is_left_out_of_the_automatic_lineup(): void
    {
        $club = Club::where('user_id', $this->owner->id)->first();
        $best = $this->actingAs($this->owner)->getJson($this->url)->json('lineup.starters');
        DB::table('players')->where('id', $best[0])->update(['injured_matches' => 2]);
        $now = $this->getJson("{$this->url}/suggestion")->assertOk()->json('lineup');
        $this->assertNotContains($best[0], $now['starters']);
        $this->assertNotContains($best[0], $now['bench']);
        $this->assertSame($club->id, Club::where('user_id', $this->owner->id)->value('id'));
    }

    public function test_the_coach_saves_a_lineup_and_the_server_checks_it(): void
    {
        $this->actingAs($this->owner);
        $team = $this->getJson($this->url)->json();
        $ids = collect($team['players']);
        $keepers = $ids->where('line', 'gk')->pluck('id')->values();
        $field = $ids->where('line', '!=', 'gk')->pluck('id')->values();
        $starters = $this->byLine($team['players'], '3-5-2B', $keepers[1]);
        $field = $field->diff($starters)->values()->merge(array_slice($starters, 1));
        $bench = array_merge([$keepers[0]], $field->take(5)->all());

        $saved = $this->putJson("{$this->url}/lineup", ['formation' => '3-5-2B', 'starters' => $starters, 'bench' => $bench])->assertOk()->json('lineup');
        $this->assertSame(['3-5-2B', false, $starters, $bench], [$saved['formation'], $saved['auto'], $saved['starters'], $saved['bench']]);
        $this->assertSame(['def' => 3, 'mid' => 5, 'att' => 2], $saved['lines']);

        $bad = fn (array $body) => $this->putJson("{$this->url}/lineup", $body + ['formation' => '4-4-2A', 'starters' => $starters, 'bench' => $bench])->assertUnprocessable();
        $bad(['formation' => '9-9-9'])->assertJsonPath('errors.formation.0', 'هذه الطريقة غير موجودة.');
        $bad(['starters' => array_slice($starters, 0, 10)])->assertJsonPath('errors.starters.0', 'التشكيلة 11 لاعباً بالضبط.');
        $bad(['bench' => [], 'starters' => array_merge([$field[0], $keepers[1]], $field->slice(1, 9)->values()->all())])->assertJsonPath('errors.starters.0', 'خانة الحارس لحارس مرمى.');
        $bad(['formation' => '3-5-2B', 'bench' => array_merge($bench, [$starters[3]])])->assertJsonPath('errors.starters.0', 'لاعب واحد لا يكون في خانتين.');
        $bad(['formation' => '3-5-2B', 'bench' => array_merge($bench, $field->slice(5, 4)->values()->all())])->assertJsonPath('errors.bench.0', 'الاحتياط 7 لاعبين على الأكثر.');
        $other = DB::table('players')->where('club_id', '!=', $this->league['my_club_id'])->value('id');
        $bad(['formation' => '3-5-2B', 'bench' => [$other]])->assertJsonPath('errors.starters.0', 'كل اللاعبين يجب أن يكونوا من فريقك.');

        // [Sprint 27 W4] As flexible as OSM: a striker may play in midfield (at the engine's out-of-position share)...
        $wrong = $starters;
        $mid = array_search('mid', array_column(FormationBook::slots('3-5-2B'), 'line'), true);
        $striker = $ids->first(fn ($p) => $p['line'] === 'att' && ! str_contains((string) $p['alt_positions'], 'M') && ! in_array($p['id'], $starters, true));
        $wrong[$mid] = $striker['id'];
        $this->putJson("{$this->url}/lineup", ['formation' => '3-5-2B', 'starters' => $wrong, 'bench' => []])->assertOk()
            ->assertJsonPath("lineup.starters.{$mid}", $striker['id']);
        // ...but a goalkeeper stays in goal.
        $keeperOut = $starters;
        $keeperOut[$mid] = $keepers[0];
        $this->putJson("{$this->url}/lineup", ['formation' => '3-5-2B', 'starters' => $keeperOut, 'bench' => []])->assertUnprocessable()
            ->assertJsonPath('errors.starters.0', DB::table('master_players')->join('players', 'players.master_player_id', '=', 'master_players.id')->where('players.id', $keepers[0])->value('master_players.name').' حارس مرمى: مكانه في المرمى أو على الدكة.');
        $this->getJson('/api/v1/data/formations')->assertOk()->assertJsonPath('off_line_bp', 7000)->assertJsonPath('far_line_bp', 5000);
        // [X2, Sprint 39 E1] Each player's share in every line, from the engine: his own in full, the next line 70%, two lines
        // away 50%, the goal 40% (a striker: midfield next, defence two lines back; his second positions may be in full).
        $place = collect($this->getJson($this->url)->json('players'))->firstWhere('id', $striker['id'])['place_bp'];
        $this->assertSame([4000, 10000], [$place['gk'], $place['att']]);
        $this->assertContains($place['mid'], [7000, 10000]);
        $this->assertContains($place['def'], [5000, 10000]);

        // Back to automatic.
        $this->deleteJson("{$this->url}/lineup")->assertOk()->assertJsonPath('lineup.auto', true);
    }

    public function test_custom_formations_keep_to_the_line_limits_with_a_clear_message(): void
    {
        $this->actingAs($this->owner);
        $cells = [['def', 1], ['def', 2], ['def', 4], ['def', 5], ['dm', 3], ['am', 2], ['am', 4], ['att', 1], ['att', 3], ['att', 5]];
        $team = $this->putJson("{$this->url}/formations/1", ['name' => 'هجومية', 'cells' => $cells])->assertOk()->json();
        $this->assertSame(['custom:1', 'هجومية', ['def' => 4, 'mid' => 3, 'att' => 3]], [$team['custom_formations'][0]['name'], $team['custom_formations'][0]['label'], $team['custom_formations'][0]['lines']]);
        $this->assertSame(['RB', 'CB', 'CB', 'LB'], array_column(array_slice($team['custom_formations'][0]['slots'], 1, 4), 'role'));

        $put = fn (array $cells, int $n = 2) => $this->putJson("{$this->url}/formations/{$n}", ['name' => 'X', 'cells' => $cells]);
        // Two at the back: below the minimum of three.
        $put([['def', 2], ['def', 4], ['dm', 1], ['dm', 3], ['dm', 5], ['am', 2], ['am', 4], ['att', 2], ['att', 3], ['att', 4]])
            ->assertUnprocessable()->assertJsonPath('errors.cells.0', 'الدفاع من 3 إلى 6 لاعبين، وفي تشكيلتك 2.');
        // No striker.
        $put([['def', 1], ['def', 2], ['def', 3], ['def', 4], ['dm', 2], ['dm', 4], ['am', 1], ['am', 2], ['am', 4], ['am', 5]])
            ->assertUnprocessable()->assertJsonPath('errors.cells.0', 'الهجوم من 1 إلى 5 لاعبين، وفي تشكيلتك 0.');
        // Seven in midfield.
        $put([['def', 2], ['def', 3], ['def', 4], ['dm', 1], ['dm', 2], ['dm', 4], ['dm', 5], ['am', 2], ['am', 4], ['am', 3]])
            ->assertUnprocessable()->assertJsonPath('errors.cells.0', 'الوسط من 2 إلى 6 لاعبين، وفي تشكيلتك 7.');
        $put(array_fill(0, 10, ['def', 3]))->assertUnprocessable()->assertJsonPath('errors.cells.0', 'ضع 10 لاعبين في خانات مختلفة (والحارس ثابت).');
        $put($cells, 4)->assertUnprocessable()->assertJsonPath('errors.number.0', 'لك 3 تشكيلات مخصصة فقط.');
        $put([['def', 3], ['def', 2], ['def', 4], ['dm', 3], ['dm', 2], ['dm', 4], ['am', 3], ['att', 3], ['att', 2], ['x', 4]])->assertJsonValidationErrors('cells.9.0');

        // A saved custom formation is one a lineup can use.
        $team = $this->getJson($this->url)->json();
        $keeper = collect($team['players'])->firstWhere('line', 'gk')['id'];
        $this->putJson("{$this->url}/lineup", ['formation' => 'custom:1', 'starters' => $this->byLine($team['players'], FormationBook::custom($cells), $keeper), 'bench' => []])
            ->assertOk()->assertJsonPath('lineup.formation', 'custom:1')->assertJsonPath('lineup.lines.att', 3);
    }

    public function test_the_coach_drags_players_anywhere_inside_their_lines_band(): void
    {
        $this->actingAs($this->owner);
        $team = $this->getJson($this->url)->json();
        $keeper = collect($team['players'])->firstWhere('line', 'gk')['id'];
        $starters = $this->byLine($team['players'], '4-3-3A', $keeper);
        $places = array_map(fn ($s) => [$s['x'], $s['y']], array_slice(FormationBook::slots('4-3-3A'), 1));
        // The striker (slot 9 of ten) drifts to the right wing; the holding midfielder (5) pushes up behind him.
        $places[8] = [650, 600];
        $places[4] = [540, 340];
        $lineup = $this->putJson("{$this->url}/lineup", ['formation' => '4-3-3A', 'starters' => $starters, 'bench' => [], 'positions' => $places])->assertOk()->json('lineup');
        $this->assertSame(['RW', 650, 600], [$lineup['slots'][9]['role'], $lineup['slots'][9]['x'], $lineup['slots'][9]['y']]);
        $this->assertSame('CAM', $lineup['slots'][5]['role']);
        // Kept: the same places come back.
        $this->assertSame('RW', $this->getJson($this->url)->json('lineup.slots.9.role'));

        // Out of his line's band: the striker dropping to the halfway line.
        $places[8] = [450, 340];
        $this->putJson("{$this->url}/lineup", ['formation' => '4-3-3A', 'starters' => $starters, 'bench' => [], 'positions' => $places])
            ->assertUnprocessable()->assertJsonPath('errors.positions.0', 'لاعب الهجوم يتحرك داخل منطقة خطه فقط.');
    }

    /** Eleven for a formation, each in his own line: the keeper given, then the best of each line in turn. */
    private function byLine(array $players, string|array $formation, int $keeper): array
    {
        $slots = is_string($formation) ? FormationBook::slots($formation) : $formation;
        $used = [$keeper => true];
        $out = [$keeper];
        foreach (array_slice($slots, 1) as $slot) {
            $p = collect($players)->first(fn ($p) => ! isset($used[$p['id']]) && $p['line'] === $slot['line']);
            $used[$p['id']] = true;
            $out[] = $p['id'];
        }

        return $out;
    }

    public function test_the_coach_picks_the_takers_from_the_whole_squad(): void
    {
        $this->actingAs($this->owner);
        $team = $this->getJson($this->url)->json();
        $starters = array_values(array_filter($team['lineup']['starters']));
        $reserve = collect($team['players'])->firstWhere('role', 'reserve') ?? collect($team['players'])->firstWhere('role', 'bench');

        $this->putJson("{$this->url}/takers", ['captain' => $starters[5], 'penalty' => $starters[9]])->assertOk()
            ->assertJsonPath('takers.captain.player_id', $starters[5])->assertJsonPath('takers.captain.auto', false)
            ->assertJsonPath('takers.penalty.player_id', $starters[9])->assertJsonPath('takers.penalty.auto', false)
            ->assertJsonPath('takers.corner.auto', true);
        // [Sprint 27 W5] Anyone in the squad: out of the eleven, the automatic one takes the role until he is back.
        $res = $this->putJson("{$this->url}/takers", ['captain' => $reserve['id']])->assertOk()
            ->assertJsonPath('takers.captain.chosen_id', $reserve['id'])->assertJsonPath('takers.captain.auto', true);
        $this->assertNotSame($reserve['id'], $res->json('takers.captain.player_id'));
        // The candidates, best first by the role's skill, with whether each plays.
        $pens = $res->json('takers.penalty.candidates');
        $this->assertSame(collect($pens)->sortByDesc('skill')->pluck('skill')->values()->all(), array_column($pens, 'skill'));
        $other = DB::table('players')->where('club_id', '!=', $this->league['my_club_id'])->value('id');
        $this->putJson("{$this->url}/takers", ['captain' => $other])->assertUnprocessable()->assertJsonPath('errors.captain.0', 'المنفذ يجب أن يكون من فريقك.');
        // "تحسين": all back to automatic.
        $this->putJson("{$this->url}/takers", [])->assertOk()->assertJsonPath('takers.captain.auto', true)->assertJsonPath('takers.captain.chosen_id', null);
    }

    public function test_a_bot_club_always_has_a_full_automatic_lineup(): void
    {
        // Sprint 16 B3: a bot keeps "تحسين" and changes nothing else until Sprint 32.
        $bot = Club::where('league_id', $this->league['id'])->whereNull('user_id')->first();
        $sheet = TeamSheet::current($bot);
        $this->assertTrue($sheet['auto']);
        $this->assertCount(11, array_filter($sheet['starters']));
        $this->assertTrue(FormationBook::has($sheet['formation']));
    }
}
