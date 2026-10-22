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
        $starters = array_merge([$keepers[1]], $field->take(10)->all());
        $bench = array_merge([$keepers[0]], $field->slice(10, 5)->values()->all());

        $saved = $this->putJson("{$this->url}/lineup", ['formation' => '3-5-2B', 'starters' => $starters, 'bench' => $bench])->assertOk()->json('lineup');
        $this->assertSame(['3-5-2B', false, $starters, $bench], [$saved['formation'], $saved['auto'], $saved['starters'], $saved['bench']]);
        $this->assertSame(['def' => 3, 'mid' => 5, 'att' => 2], $saved['lines']);

        $bad = fn (array $body) => $this->putJson("{$this->url}/lineup", $body + ['formation' => '4-4-2A', 'starters' => $starters, 'bench' => $bench])->assertUnprocessable();
        $bad(['formation' => '9-9-9'])->assertJsonPath('errors.formation.0', 'هذه الطريقة غير موجودة.');
        $bad(['starters' => array_slice($starters, 0, 10)])->assertJsonPath('errors.starters.0', 'التشكيلة 11 لاعباً بالضبط.');
        $bad(['starters' => array_merge([$field[0], $keepers[1]], $field->slice(1, 9)->values()->all())])->assertJsonPath('errors.starters.0', 'خانة الحارس لحارس مرمى.');
        $bad(['bench' => array_merge($bench, [$starters[3]])])->assertJsonPath('errors.starters.0', 'لاعب واحد لا يكون في خانتين.');
        $bad(['bench' => array_merge($bench, $field->slice(15)->values()->all(), [$keepers[0], $field[0]])])->assertJsonPath('errors.bench.0', 'الاحتياط 7 لاعبين على الأكثر.');
        $other = DB::table('players')->where('club_id', '!=', $this->league['my_club_id'])->value('id');
        $bad(['bench' => [$other]])->assertJsonPath('errors.starters.0', 'كل اللاعبين يجب أن يكونوا من فريقك.');

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
        $this->putJson("{$this->url}/lineup", ['formation' => 'custom:1', 'starters' => $team['lineup']['starters'], 'bench' => $team['lineup']['bench']])
            ->assertOk()->assertJsonPath('lineup.formation', 'custom:1')->assertJsonPath('lineup.lines.att', 3);
    }

    public function test_the_coach_picks_the_takers_among_the_starters(): void
    {
        $this->actingAs($this->owner);
        $team = $this->getJson($this->url)->json();
        $starters = array_values(array_filter($team['lineup']['starters']));
        $reserve = collect($team['players'])->firstWhere('role', 'reserve') ?? collect($team['players'])->firstWhere('role', 'bench');

        $this->putJson("{$this->url}/takers", ['captain' => $starters[5], 'penalty' => $starters[9]])->assertOk()
            ->assertJsonPath('takers.captain', ['player_id' => $starters[5], 'auto' => false])
            ->assertJsonPath('takers.penalty', ['player_id' => $starters[9], 'auto' => false])
            ->assertJsonPath('takers.corner.auto', true);
        $this->putJson("{$this->url}/takers", ['captain' => $reserve['id']])->assertUnprocessable()->assertJsonPath('errors.captain.0', 'المنفذ يجب أن يكون من الأساسيين.');
        // "تحسين": all back to automatic.
        $this->putJson("{$this->url}/takers", [])->assertOk()->assertJsonPath('takers.captain.auto', true);
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
