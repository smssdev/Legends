<?php

namespace Tests\Feature;

use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** Resigning [PLAN 2.2, Sprint 32]: not in the preparation, not on the winter day, not in the last 25%; no way back. */
class ResignTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private User $coach;

    private array $league;

    private object $season;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->artisan('clock:travel', ['by' => 'reset']);
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner, ['team_count' => 6, 'rounds_per_day' => 1, 'round_times' => ['21:00'],
            'starts_at' => GameClock::now()->addDay()->toIso8601ZuluString()]);
        $this->coach = $this->approvedCoach($this->owner, $this->league);
        $this->actingAs($this->coach)->postJson("/api/v1/leagues/{$this->league['id']}/clubs/{$this->botClub($this->league['id'])}/claim")->assertCreated();
        $this->season = DB::table('seasons')->where('league_id', $this->league['id'])->first();
    }

    protected function tearDown(): void
    {
        $this->artisan('clock:travel', ['by' => 'reset']);
        Carbon::setTestNow();
        parent::tearDown();
    }

    /** Travel the game clock to this moment, as a developer would with clock:travel. */
    private function gameClockTo(string $at): void
    {
        $seconds = (int) GameClock::now()->diffInSeconds(Carbon::parse($at, 'UTC'), false);
        $this->artisan('clock:travel', ['by' => ($seconds >= 0 ? '+' : '').$seconds.'s'])->assertSuccessful();
        $this->artisan('leagues:start');
    }

    private function resign()
    {
        return $this->actingAs($this->coach)->postJson("/api/v1/leagues/{$this->league['id']}/resign");
    }

    private function window(string $kind): object
    {
        return DB::table('transfer_windows')->where('season_id', $this->season->id)->where('kind', $kind)->first();
    }

    public function test_no_resigning_in_the_preparation_nor_on_the_winter_day(): void
    {
        $this->resign()->assertConflict()->assertJsonPath('message', 'لا استقالة في فترة الإعداد. يمكنك الاستقالة بعد أن تبدأ الجولات.');
        $this->gameClockTo(Carbon::parse($this->window('summer')->closes_at, 'UTC')->subMinute());
        $this->resign()->assertConflict();
        $winter = $this->window('winter');
        $this->gameClockTo($winter->opens_at);
        $this->resign()->assertConflict()->assertJsonPath('message', 'لا استقالة في يوم الانتقالات الشتوي.');
    }

    public function test_no_resigning_in_the_last_quarter(): void
    {
        $this->gameClockTo(Carbon::parse($this->window('summer')->closes_at, 'UTC')->addMinute());
        DB::table('seasons')->where('id', $this->season->id)->update(['rounds_played' => $this->season->lock_from_round - 1]);
        $this->resign()->assertConflict()->assertJsonPath('message', 'لا استقالة في آخر ربع من جولات الدوري.');
    }

    public function test_a_resigned_coach_leaves_his_club_to_a_bot_and_cannot_come_back_this_season(): void
    {
        $this->gameClockTo(Carbon::parse($this->window('summer')->closes_at, 'UTC')->addMinute());
        $club = DB::table('clubs')->where('user_id', $this->coach->id)->value('id');
        $this->resign()->assertOk()->assertJsonPath('left', true);
        $this->assertNull(DB::table('clubs')->where('id', $club)->value('user_id'));
        $this->assertSame('resigned', DB::table('league_memberships')->where('user_id', $this->coach->id)->value('left_reason'));
        $this->actingAs($this->coach)->postJson('/api/v1/leagues/join', ['code' => $this->league['code']])
            ->assertConflict()->assertJsonPath('message', 'غادرت هذا الدوري هذا الموسم، ويمكنك العودة في الموسم الجديد.');
        // The owner runs the league: he does not resign.
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/resign")->assertConflict();
    }
}
