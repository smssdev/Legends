<?php

namespace Tests\Feature;

use App\Auth\AccountHolidays;
use App\League\MatchPrep;
use App\Models\Club;
use App\Models\User;
use App\Support\Activity;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [UP13] The owner's spec (7): 14 days unused and the account goes (warned at 12); the assistant leads an absent coach's team. */
class AccountLifecycleTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_an_unused_account_is_warned_at_twelve_days_and_deleted_at_fourteen(): void
    {
        Carbon::setTestNow('2026-10-01 12:00:00');
        $idle = User::factory()->create();
        $away = User::factory()->create();
        $admin = User::factory()->create(['role' => 'admin']);
        $back = User::factory()->create();
        $this->actingAs($away)->postJson('/api/v1/auth/vacation', ['days' => 5, 'reason' => 'سفر'])->assertOk();

        Carbon::setTestNow('2026-10-13 13:00:00');
        // The two unused: warned (the one back from holiday counts from its end, the admin never).
        $this->assertSame([2, 0], AccountHolidays::sweep());
        $this->assertSame(1, DB::table('messages')->where('user_id', $idle->id)->where('type', 'inactive_warning')->count());
        $this->assertSame([0, 0], AccountHolidays::sweep());   // told once
        // Coming back clears the warning.
        $this->actingAs($back)->getJson('/api/v1/auth/me')->assertOk();
        Activity::record($back->id, 'visits');
        $this->assertNull(DB::table('users')->where('id', $back->id)->value('inactive_warned_at'));

        Carbon::setTestNow('2026-10-15 13:00:00');
        [, $deleted] = AccountHolidays::sweep();
        $this->assertGreaterThanOrEqual(1, $deleted);
        $this->assertNull(User::find($idle->id));
        $this->assertNotNull(User::find($back->id));
        $this->assertNotNull(User::find($admin->id));
    }

    public function test_the_assistant_leads_when_the_coach_has_not_been_in_since_the_last_match(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template();
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner);
        $club = Club::findOrFail($league['my_club_id']);
        $fixtures = DB::table('fixtures')->where('competition', 'league')->where('is_bye', false)
            ->where(fn ($q) => $q->where('home_id', $club->id)->orWhere('away_id', $club->id))->orderBy('scheduled_at')->get();
        [$first, $second] = [$fixtures[0], $fixtures[1]];
        // The first match: nothing before it to have missed.
        $this->assertFalse(MatchPrep::absent($club, $first));
        $at = fn (string $when) => DB::table('league_memberships')->where('user_id', $owner->id)->update(['last_active_at' => $when]);
        $at(Carbon::parse($first->scheduled_at, 'UTC')->subHour());
        $this->assertTrue(MatchPrep::absent($club, $second));
        $at(Carbon::parse($first->scheduled_at, 'UTC')->addHours(3));
        $this->assertFalse(MatchPrep::absent($club, $second));
        // On holiday, always.
        DB::table('users')->where('id', $owner->id)->update(['vacation_from' => GameClock::now(), 'vacation_until' => Carbon::parse($second->scheduled_at, 'UTC')->addDay()]);
        $this->assertTrue(MatchPrep::absent($club->fresh(), $second));
    }
}
