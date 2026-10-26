<?php

namespace Tests\Feature;

use App\League\ClubLedger;
use App\League\NextFixture;
use App\League\Spy;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** Spying on the next opponent, item by item of docs/features/spy.md [Sprint 30]. */
class SpyTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private User $rival;

    private array $league;

    private int $mine;

    private int $theirs;

    private object $fixture;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'rounds_per_day' => 1, 'round_times' => ['21:00']]);
        $this->mine = $this->league['my_club_id'];
        $this->fixture = NextFixture::of($this->mine);
        $this->theirs = $this->fixture->home_id === $this->mine ? $this->fixture->away_id : $this->fixture->home_id;
        $this->rival = $this->approvedCoach($this->owner, $this->league);
        $this->actingAs($this->rival)->postJson("/api/v1/leagues/{$this->league['id']}/clubs/{$this->theirs}/claim")->assertCreated();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function url(): string
    {
        return "/api/v1/leagues/{$this->league['id']}/spy";
    }

    private function send()
    {
        return $this->actingAs($this->owner)->postJson($this->url());
    }

    /** The rival saves his own tactics, hidden ones included. */
    private function rivalTactics(array $t): void
    {
        $this->actingAs($this->rival)->putJson("/api/v1/leagues/{$this->league['id']}/team/tactics", $t)->assertOk();
    }

    public function test_1_sending_pays_once_and_only_before_the_lock(): void
    {
        $before = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        $this->send()->assertOk()->assertJsonPath('report.club.id', $this->theirs);
        $this->assertSame($before - Spy::cost($this->league['id']), (int) DB::table('clubs')->where('id', $this->mine)->value('balance'));
        $this->send()->assertConflict()->assertJsonPath('message', 'أرسلت جاسوساً لهذه المباراة.');

        DB::table('spy_reports')->delete();
        DB::table('fixtures')->where('id', $this->fixture->id)->update(['status' => 'locked']);
        $this->send()->assertConflict();
        DB::table('fixtures')->where('id', $this->fixture->id)->update(['status' => 'scheduled']);
        ClubLedger::post($this->mine, 'wages', -100_000_000, 'debt');
        $this->send()->assertConflict()->assertJsonPath('message', 'رصيد النادي لا يكفي.');
    }

    public function test_2_the_report_has_the_five_items_as_they_were_then(): void
    {
        $this->rivalTactics(['tackling' => 2, 'marking' => 'man', 'trap' => 1]);
        $report = $this->send()->assertOk()->json('report');
        $this->assertSame(['club', 'at', 'formation', 'starters', 'bench', 'tactics', 'form', 'fitness'], array_keys($report));
        $this->assertCount(11, $report['starters']);
        $this->assertSame(['tackling', 'marking', 'plan', 'trap'], array_keys($report['tactics']));
        $this->assertSame(2, $report['tactics']['tackling']);
        $this->assertSame(100, $report['fitness']);
        // The rival changes his mind afterwards: the report stays as it was.
        $this->rivalTactics(['tackling' => 0]);
        $this->actingAs($this->owner)->getJson($this->url())->assertJsonPath('report.tactics.tackling', 2);
    }

    public function test_3_and_4_nothing_hidden_reaches_the_spy_and_the_rival_is_not_told(): void
    {
        $this->rivalTactics(['pressing' => 95, 'style' => 10, 'tempo' => 90, 'att' => 'only', 'mid' => 'push', 'def' => 'fullbacks']);
        $told = DB::table('messages')->where('user_id', $this->rival->id)->count();
        $body = $this->send()->assertOk()->getContent().$this->actingAs($this->owner)->getJson($this->url())->getContent();
        // As keys (the lines' names are values on every player): pressing, style, tempo, the three positions, the shape.
        foreach (['pressing', 'style', 'tempo', 'att', 'mid', 'def', 'shape', 'secret', 'boost'] as $hidden) {
            $this->assertStringNotContainsString("\"{$hidden}\":", $body, $hidden);
        }
        foreach (['only', 'push', 'fullbacks'] as $value) {
            $this->assertStringNotContainsString("\"{$value}\"", $body, $value);
        }
        $this->assertSame($told, DB::table('messages')->where('user_id', $this->rival->id)->count());
        $this->assertStringNotContainsString('spy', $this->actingAs($this->rival)->getJson("/api/v1/leagues/{$this->league['id']}/team/next-match")->getContent());
    }
}
