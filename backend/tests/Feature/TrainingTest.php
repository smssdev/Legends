<?php

namespace Tests\Feature;

use App\League\ClubLedger;
use App\League\TeamSheet;
use App\Models\Club;
use App\Models\User;
use App\Support\GameClock;
use App\Training\Gain;
use App\Training\Training;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** Training [PLAN 2.8, Sprint 27]: the slots, the sessions with the coach away, the +1, the ceiling and the cost. */
class TrainingTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    private int $mine;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'starts_at' => GameClock::now()->addDays(2)->toIso8601ZuluString()]);
        $this->mine = $this->league['my_club_id'];
        $this->lineCoaches($this->mine);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function url(string $path = ''): string
    {
        return "/api/v1/leagues/{$this->league['id']}/training{$path}";
    }

    /** One of my players with room to grow, in a line if asked. */
    private function trainee(?string $line = null): object
    {
        return DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('players.club_id', $this->mine)->whereColumn('master_players.potential', '>', 'players.overall')
            ->when($line, fn ($q) => $q->where('master_players.line', $line))
            ->orderBy('players.id')->first(['players.id', 'players.overall', 'master_players.line', 'master_players.potential', 'master_players.pac']);
    }

    private function interval(): int
    {
        return Training::interval($this->league['id']);
    }

    public function test_no_training_without_the_lines_coach_and_a_session_is_six_hours_everywhere(): void
    {
        DB::table('staff_specialists')->where('club_id', $this->mine)->where('type', 'mid_coach')->delete();
        $this->actingAs($this->owner)->postJson($this->url(), ['player_id' => $this->trainee('mid')->id])->assertStatus(422)
            ->assertJsonPath('message', 'لا تدريب بلا مدرب: تعاقد مع مدرب الوسط من الجهاز الفني أولاً.');
        $this->actingAs($this->owner)->postJson($this->url(), ['player_id' => $this->trainee('def')->id])->assertOk();
        $this->assertSame(6 * 3600, Training::interval($this->league['id']));
        DB::table('leagues')->where('id', $this->league['id'])->update(['timer_scale' => 5000]);
        $this->assertSame(6 * 3600, Training::interval($this->league['id']));
    }

    public function test_a_player_goes_in_his_lines_slot_and_a_second_one_of_his_line_waits(): void
    {
        $p = $this->trainee('mid');
        $page = $this->actingAs($this->owner)->postJson($this->url(), ['player_id' => $p->id])->assertOk();
        $slot = collect($page->json('slots'))->firstWhere('line', 'mid');
        $this->assertSame($p->id, $slot['player']['id']);
        $this->assertNotNull($slot['next_at']);

        $other = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.club_id', $this->mine)
            ->where('master_players.line', 'mid')->whereColumn('master_players.potential', '>', 'players.overall')->where('players.id', '!=', $p->id)->value('players.id');
        // [UP8] One per line: the second midfielder waits while the first one trains.
        $this->assertStringContainsString('لاعب واحد من كل خط', $this->postJson($this->url(), ['player_id' => $other])->assertConflict()->json('message'));
        $this->assertSame($p->id, (int) DB::table('training_slots')->value('player_id'));
        // Once the slot is free (his +1 done, finished for coins, or stopped), the other one goes in.
        $this->deleteJson($this->url('/mid'))->assertOk();
        $this->postJson($this->url(), ['player_id' => $other])->assertOk();
        $this->assertSame(1, DB::table('training_slots')->where('club_id', $this->mine)->count());
        $this->assertSame($other, (int) DB::table('training_slots')->value('player_id'));

        // Not mine, and at his ceiling: refused in Arabic.
        $theirs = DB::table('players')->where('league_id', $this->league['id'])->where('club_id', '!=', $this->mine)->value('id');
        $this->postJson($this->url(), ['player_id' => $theirs])->assertNotFound()->assertJsonPath('message', 'اللاعب ليس في فريقك.');
        $maxed = $this->trainee('def');
        DB::table('players')->where('id', $maxed->id)->update(['training_bonus' => 99 - $maxed->overall]);
        $maxed = $maxed->id;
        $this->postJson($this->url(), ['player_id' => $maxed])->assertUnprocessable()->assertJsonPath('message', 'وصل هذا اللاعب إلى 99، أعلى تقييم في اللعبة.');

        $this->deleteJson($this->url('/mid'))->assertOk();
        $this->assertSame(0, DB::table('training_slots')->count());
    }

    public function test_sessions_run_with_the_coach_away_each_one_paid_and_the_missed_ones_caught_up(): void
    {
        $p = $this->trainee();
        Training::add($this->mine, $p->id);
        $before = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        $cost = Training::cost($this->league['id']);
        $this->assertGreaterThan(0, $cost);

        Carbon::setTestNow(GameClock::now()->addSeconds($this->interval() - 60));
        $this->artisan('training:tick')->assertSuccessful();
        $this->assertSame(0, (int) DB::table('players')->where('id', $p->id)->value('training_progress'));

        // Three sessions' time passes with nobody online: the scheduler runs all three.
        Carbon::setTestNow(GameClock::now()->addSeconds($this->interval() * 2 + 60));
        $this->artisan('training:tick')->assertSuccessful();
        $this->assertSame(3, (int) DB::table('training_slots')->value('sessions'));
        $this->assertSame(3, DB::table('club_transactions')->where('club_id', $this->mine)->where('type', 'training')->count());
        $this->assertSame($before - 3 * $cost, (int) DB::table('clubs')->where('id', $this->mine)->value('balance'));
        $this->assertGreaterThan(0, (int) DB::table('players')->where('id', $p->id)->value('training_progress'));
        // Running it again changes nothing: each session once.
        $this->artisan('training:tick')->assertSuccessful();
        $this->assertSame(3, DB::table('club_transactions')->where('type', 'training')->count());
        $this->assertSame($before - 3 * $cost, ClubLedger::sum($this->mine));
    }

    public function test_a_full_bar_is_plus_one_on_the_rating_the_attributes_and_the_value_then_the_slot_empties(): void
    {
        $p = $this->trainee('att');
        $value = (int) DB::table('players')->where('id', $p->id)->value('value');
        Training::add($this->mine, $p->id);
        DB::table('players')->where('id', $p->id)->update(['training_progress' => 9999]);
        Carbon::setTestNow(GameClock::now()->addSeconds($this->interval()));
        $this->artisan('training:tick')->assertSuccessful();

        $row = DB::table('players')->where('id', $p->id)->first();
        $this->assertSame(1, (int) $row->training_bonus);
        $this->assertSame(0, (int) $row->training_progress);
        $this->assertGreaterThan($value, (int) $row->value);
        $this->assertSame(0, DB::table('training_slots')->count());
        $this->assertStringContainsString('فأصبحت قوته '.($p->overall + 1), $this->actingAs($this->owner)->getJson('/api/v1/messages')->json('messages.0.body'));

        // The engine and the squad screen read the trained numbers.
        $squad = collect(TeamSheet::squad(Club::find($this->mine)))->firstWhere('id', $p->id);
        $this->assertSame($p->overall + 1, $squad['a']['ovr']);
        $this->assertSame(min(99, $p->pac + 1), $squad['a']['pac']);
        $card = collect($this->getJson("/api/v1/leagues/{$this->league['id']}/team")->json('players'))->firstWhere('id', $p->id);
        $this->assertSame($p->overall + 1, $card['overall']);
        $this->assertSame(1, $card['training_bonus']);
    }

    /** [X16] Open training: the potential no longer stops it, it only slows it; 99 is the end. */
    public function test_training_goes_past_the_potential_slower_up_to_99(): void
    {
        $p = $this->trainee();
        DB::table('players')->where('id', $p->id)->update(['training_bonus' => $p->potential - $p->overall - 1, 'training_progress' => 9999]);
        Training::add($this->mine, $p->id);
        Carbon::setTestNow(GameClock::now()->addSeconds($this->interval()));
        Training::due();
        $this->assertSame($p->potential - $p->overall, (int) DB::table('players')->where('id', $p->id)->value('training_bonus'));
        // At the potential: still trainable, and each +1 takes three times the sessions.
        $this->actingAs($this->owner)->postJson($this->url(), ['player_id' => $p->id])->assertOk();
        $row = collect($this->getJson($this->url())->json('players'))->firstWhere('id', $p->id);
        $this->assertTrue($row['over_potential']);
        $this->assertFalse($row['maxed']);
        $gain = Gain::fromConfig();
        $this->assertSame(3 * $gain->sessions($p->potential), $gain->sessions($p->potential, $p->potential));
        $this->assertSame(5 * $gain->sessions($p->potential + 1), $gain->sessions($p->potential + 1, $p->potential));
        // 99 is the end.
        $this->assertSame(0, $gain->run(99, 70, 500, 'k'));
        $this->assertGreaterThan(0, $gain->run(70, 70, 500, 'k'));
    }

    public function test_without_money_the_session_is_missed_and_a_sold_player_leaves_his_slot(): void
    {
        $p = $this->trainee();
        Training::add($this->mine, $p->id);
        ClubLedger::post($this->mine, 'wages', -100_000_000, 'debt');
        Carbon::setTestNow(GameClock::now()->addSeconds($this->interval()));
        Training::due();
        $this->assertSame(0, (int) DB::table('players')->where('id', $p->id)->value('training_progress'));
        $this->assertSame(0, DB::table('club_transactions')->where('type', 'training')->count());
        $this->assertSame(1, (int) DB::table('training_slots')->value('sessions'));

        DB::table('players')->where('id', $p->id)->update(['club_id' => null]);
        Carbon::setTestNow(GameClock::now()->addSeconds($this->interval()));
        Training::due();
        $this->assertSame(0, DB::table('training_slots')->count());
    }

    public function test_the_stronger_the_slower_and_each_step_within_its_spread(): void
    {
        // sim:training checks the season target on the real data (CI runs it after data:import).
        $gain = Gain::fromConfig();
        $this->assertSame(6, $gain->sessions(65));
        $this->assertSame(25, $gain->sessions(89));
        $this->assertGreaterThan($gain->sessions(75), $gain->sessions(80));
        foreach (range(1, 200) as $i) {
            $step = $gain->step(65, "k{$i}");
            $this->assertTrue($step >= intdiv(10000 / 6, 2) && $step <= intdiv(10000, 6) * 3 / 2 + 1, (string) $step);
        }
        $this->assertSame($gain->step(80, 'same'), $gain->step(80, 'same'));
        // Past the potential it goes on, far slower than below it [X16]: up to 72 in a few dozen sessions, then a crawl.
        $this->assertSame(2, $gain->run(70, 72, 30, 'cap'));
        $this->assertLessThan(10, $gain->run(72, 72, 300, 'cap'));
    }
}
