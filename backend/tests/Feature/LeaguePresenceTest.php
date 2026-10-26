<?php

namespace Tests\Feature;

use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** Absence, holidays, the owner's kick, and the invite link [Sprint 14, PLAN 2.1, 2.2]. */
class LeaguePresenceTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private User $coach;

    private array $league;

    private int $club;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template();
        $this->owner = User::factory()->create();
        // The season starts in 2 days; the coach joins before it.
        $this->league = $this->makeLeague($this->owner, ['starts_at' => GameClock::now()->addDays(2)->toIso8601ZuluString()]);
        $this->coach = $this->approvedCoach($this->owner, $this->league);
        $this->club = $this->botClub($this->league['id']);
        $this->actingAs($this->coach)->postJson("/api/v1/leagues/{$this->league['id']}/clubs/{$this->club}/claim")->assertCreated();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function passTime(string $by): void
    {
        Carbon::setTestNow(GameClock::now()->add($by));
        $this->artisan('leagues:start')->assertSuccessful();
        $this->artisan('leagues:absence')->assertSuccessful();
    }

    private function me(User $user): array
    {
        return $this->actingAs($user)->getJson("/api/v1/leagues/{$this->league['id']}")->assertOk()->json('league');
    }

    private function membershipId(User $user): int
    {
        return (int) DB::table('league_memberships')->where('league_id', $this->league['id'])->where('user_id', $user->id)->whereNull('left_at')->value('id');
    }

    private function coachLeft(): ?string
    {
        return DB::table('league_memberships')->where('user_id', $this->coach->id)->value('left_reason');
    }

    public function test_quiet_days_before_the_season_never_count(): void
    {
        // A whole week quiet: 2 days before the start, and the start itself counts as day zero.
        $this->passTime('2 days');
        $this->assertSame('running', DB::table('leagues')->value('status'));
        $this->assertNull($this->coachLeft());
        $this->passTime('47 hours');
        $this->assertNull(DB::table('league_memberships')->where('user_id', $this->coach->id)->value('absence_warned_at'));
        $this->assertNull($this->coachLeft());
    }

    public function test_a_warning_at_48_hours_and_away_after_3_days(): void
    {
        $this->passTime('2 days');
        $this->passTime('48 hours');
        $this->assertNotNull(DB::table('league_memberships')->where('user_id', $this->coach->id)->value('absence_warned_at'));

        // Any visit clears it and starts the count again.
        $me = $this->me($this->coach)['me'];
        $this->assertFalse($me['absence_warning']);
        $this->assertSame(GameClock::now()->addDays(3)->toIso8601ZuluString(), $me['away_deadline']);
        $this->passTime('71 hours');
        $this->assertNull($this->coachLeft());
        $this->passTime('1 hour');
        $this->assertSame('absent', $this->coachLeft());

        // The club goes back to a bot as it is, free for another coach; he cannot come back this season.
        $this->assertNull(DB::table('clubs')->where('id', $this->club)->value('user_id'));
        $this->assertSame(3_000_000, (int) DB::table('clubs')->where('id', $this->club)->value('balance'));
        // The owner was just as quiet, and the rule is the same for the owner: both left; everyone sees why.
        $this->assertSame([[$this->coach->name, 'absent', null], [$this->owner->name, 'absent', null]],
            collect($this->me($this->owner)['departures'])->map(fn ($d) => [$d['user'], $d['reason'], $d['kick_reason']])
                ->sortBy(fn ($d) => $d[0] === $this->coach->name ? 0 : 1)->values()->all());
        $this->actingAs($this->coach)->postJson("/api/v1/leagues/{$this->league['id']}/clubs/{$this->club}/claim")->assertConflict();
    }

    public function test_activity_is_the_league_pages_not_the_account(): void
    {
        $other = $this->makeLeague(User::factory()->create());
        $this->passTime('2 days');
        $this->passTime('2 days');
        // Busy elsewhere does not count here.
        $this->actingAs($this->coach)->getJson('/api/v1/leagues')->assertOk();
        $this->actingAs($this->coach)->getJson("/api/v1/leagues/{$other['id']}")->assertNotFound();
        $this->passTime('1 day');
        $this->assertSame('absent', $this->coachLeft());
    }

    public function test_a_league_holiday_of_up_to_7_days_once_a_season_needs_a_reason_the_owner_approves(): void
    {
        $url = "/api/v1/leagues/{$this->league['id']}/vacation";
        $why = 'سفر للعمل خارج البلد';
        $this->actingAs($this->coach)->postJson($url, ['days' => 8, 'reason' => $why])->assertUnprocessable();
        $this->postJson($url, ['days' => 3])->assertUnprocessable()->assertJsonValidationErrors('reason');
        // The owner's own holiday starts at once.
        $this->actingAs($this->owner)->postJson($url, ['days' => 1, 'reason' => $why])->assertOk()->assertJsonPath('league.me.on_holiday', true);
        $this->actingAs(User::factory()->create())->postJson($url, ['days' => 3, 'reason' => $why])->assertForbidden();

        $this->passTime('2 days');
        $me = $this->actingAs($this->coach)->postJson($url, ['days' => 7, 'reason' => $why])->assertOk()->json('league.me');
        $this->assertFalse($me['on_holiday']);
        $this->assertTrue($me['vacation_requested']);
        $this->postJson($url, ['days' => 2, 'reason' => $why])->assertConflict()->assertJsonPath('message', 'طلبك للإجازة ينتظر رد مسؤول الدوري.');
        $this->assertSame(1, DB::table('messages')->where('user_id', $this->owner->id)->where('type', 'vacation_request')->count());

        // Only the owner sees the reason, and only the owner decides.
        $mid = $this->membershipId($this->coach);
        $members = $this->actingAs($this->owner)->getJson("/api/v1/leagues/{$this->league['id']}")->json('league.members');
        $this->assertSame($why, collect($members)->firstWhere('id', $mid)['vacation_request']['reason']);
        $this->assertNull(collect($this->actingAs($this->coach)->getJson("/api/v1/leagues/{$this->league['id']}")->json('league.members'))->firstWhere('id', $mid)['vacation_request']);
        $this->actingAs($this->coach)->postJson("/api/v1/leagues/{$this->league['id']}/members/{$mid}/vacation/approve")->assertForbidden();
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/members/{$mid}/vacation/approve")->assertOk();
        $this->assertSame(1, DB::table('messages')->where('user_id', $this->coach->id)->where('type', 'vacation_approved')->count());
        $me = $this->actingAs($this->coach)->getJson("/api/v1/leagues/{$this->league['id']}")->json('league.me');
        $this->assertTrue($me['on_holiday']);
        $this->assertNull($me['away_deadline']);
        $this->postJson($url, ['days' => 2, 'reason' => $why])->assertConflict()->assertJsonPath('message', 'استخدمت إجازة هذا الموسم من قبل.');

        // Six days away on holiday: nothing happens. It ends on day 7, and the count starts from there.
        $this->passTime('6 days');
        $this->assertNull($this->coachLeft());
        $this->passTime('1 day');
        $this->passTime('71 hours');
        $this->assertNull($this->coachLeft());
        $this->passTime('1 hour');
        $this->assertSame('absent', $this->coachLeft());
    }

    public function test_a_refused_holiday_can_be_asked_again(): void
    {
        $url = "/api/v1/leagues/{$this->league['id']}/vacation";
        $this->actingAs($this->coach)->postJson($url, ['days' => 3, 'reason' => 'ظرف عائلي طارئ'])->assertOk();
        $mid = $this->membershipId($this->coach);
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/members/{$mid}/vacation/reject")->assertOk();
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/members/{$mid}/vacation/reject")->assertConflict();
        $this->assertSame(1, DB::table('messages')->where('user_id', $this->coach->id)->where('type', 'vacation_rejected')->count());
        $this->actingAs($this->coach)->postJson($url, ['days' => 3, 'reason' => 'ظرف عائلي طارئ'])->assertOk()->assertJsonPath('league.me.vacation_requested', true);
    }

    public function test_the_account_holiday_covers_every_league_without_asking(): void
    {
        $this->actingAs($this->coach)->postJson('/api/v1/auth/vacation', ['days' => 15])->assertUnprocessable();
        $this->postJson('/api/v1/auth/vacation', ['days' => 10])->assertOk()->assertJsonPath('user.vacation.on', true);
        $this->postJson('/api/v1/auth/vacation', ['days' => 2])->assertConflict()->assertJsonPath('message', 'أنت في إجازة الآن.');
        $this->assertTrue($this->getJson("/api/v1/leagues/{$this->league['id']}")->json('league.me.on_holiday'));

        // Nine days away: the team stays. It ends on day 10, and the count starts from there.
        $this->passTime('9 days');
        $this->assertNull($this->coachLeft());
        $this->passTime('1 day');
        $this->passTime('71 hours');
        $this->assertNull($this->coachLeft());
        $this->passTime('1 hour');
        $this->assertSame('absent', $this->coachLeft());
    }

    public function test_the_next_account_holiday_waits_for_the_rest_days(): void
    {
        $this->actingAs($this->coach)->deleteJson('/api/v1/auth/vacation')->assertConflict();
        $this->postJson('/api/v1/auth/vacation', ['days' => 2])->assertOk();
        $this->passTime('1 day');
        $this->actingAs($this->coach)->deleteJson('/api/v1/auth/vacation')->assertOk()->assertJsonPath('user.vacation.on', false);
        $this->postJson('/api/v1/auth/vacation', ['days' => 2])->assertConflict();
        $this->passTime('14 days');
        $this->actingAs($this->coach)->postJson('/api/v1/auth/vacation', ['days' => 2])->assertOk();
    }

    public function test_the_owner_kicks_a_coach_with_a_reason_everyone_sees(): void
    {
        $third = $this->approvedCoach($this->owner, $this->league);
        $this->actingAs($third)->postJson("/api/v1/leagues/{$this->league['id']}/clubs/{$this->botClub($this->league['id'])}/claim")->assertCreated();
        $members = collect($this->me($this->owner)['members']);
        $coachRow = $members->firstWhere('user.id', $this->coach->id);
        $ownerRow = $members->firstWhere('user.id', $this->owner->id);
        $this->assertNotNull($coachRow['last_active_at']);
        // Coaches do not watch each other's activity.
        $this->assertNull(collect($this->me($third)['members'])->firstWhere('user.id', $this->coach->id)['last_active_at']);

        $kick = "/api/v1/leagues/{$this->league['id']}/members/{$coachRow['id']}/kick";
        $this->actingAs($third)->postJson($kick, ['reason' => 'لا يلعب'])->assertForbidden();
        $this->actingAs($this->owner)->postJson($kick, [])->assertJsonValidationErrors('reason');
        $this->postJson("/api/v1/leagues/{$this->league['id']}/members/{$ownerRow['id']}/kick", ['reason' => 'تجربة'])->assertConflict();
        $this->postJson($kick, ['reason' => 'لا يدخل أبداً'])->assertOk();
        $this->postJson($kick, ['reason' => 'مرة ثانية'])->assertConflict();

        $this->assertSame('kicked', $this->coachLeft());
        $this->assertNull(DB::table('clubs')->where('id', $this->club)->value('user_id'));
        $seen = $this->me($third)['departures'][0];
        $this->assertSame([$this->coach->name, 'kicked', 'لا يدخل أبداً'], [$seen['user'], $seen['reason'], $seen['kick_reason']]);
        // Kicked: gone from the league, and no way back this season.
        $this->actingAs($this->coach)->getJson("/api/v1/leagues/{$this->league['id']}/clubs")->assertOk();
        $this->postJson("/api/v1/leagues/{$this->league['id']}/clubs/{$this->club}/claim")->assertConflict()
            ->assertJsonPath('message', 'غادرت هذا الدوري هذا الموسم، ويمكنك العودة في الموسم الجديد.');
    }

    public function test_the_invite_link_shows_the_league_card_for_whatsapp(): void
    {
        DB::table('leagues')->update(['name' => 'دوري <الشلة> & "أصحاب"']);
        $html = $this->get('/join/'.strtolower($this->league['code']))->assertOk()->assertHeader('Content-Type', 'text/html; charset=UTF-8')->getContent();
        $this->assertStringContainsString('<meta property="og:title" content="انضم لـدوري &lt;الشلة&gt; &amp; &quot;أصحاب&quot; في GLM">', $html);
        $this->assertStringContainsString(e($this->owner->name).' يدعوك', $html);
        $this->assertStringContainsString('content="'.url('/brand/og-invite.png').'"', $html);
        $this->assertStringContainsString('content="'.url('/join/'.$this->league['code']).'"', $html);

        // Through the public link (Tailscale Funnel on this machine): https and the public host.
        $this->get('/join/'.$this->league['code'], ['X-Forwarded-Proto' => 'https', 'X-Forwarded-Host' => 'legends.tail1234.ts.net', 'X-Forwarded-Port' => '443'])
            ->assertSee('content="https://legends.tail1234.ts.net/brand/og-invite.png"', false);

        // An unknown code still opens the app, with a plain invitation.
        $this->get('/join/NOPE1234')->assertOk()->assertSee('دعوة إلى GLM', false);
        $this->assertSame(url('/join/'.$this->league['code']), $this->me($this->owner)['invite_url']);
    }
}
