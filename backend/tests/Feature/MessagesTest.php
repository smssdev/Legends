<?php

namespace Tests\Feature;

use App\Events\MessageReceived;
use App\Events\MessagesRead;
use App\Messages\Inbox;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** The inbox [Sprint 22]: messages from the game, live on the account's channel, read on every screen. */
class MessagesTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create(['name' => 'المنشئ']);
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'rounds_per_day' => 1, 'round_times' => ['21:00'],
            'starts_at' => GameClock::now()->addDays(2)->toIso8601ZuluString()]);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function inbox(User $user): array
    {
        return $this->actingAs($user)->getJson('/api/v1/messages')->assertOk()
            // [Sprint 59 F1] The fields the app reads through its generated model (MessagesAnswer in openapi.yaml).
            ->assertJsonStructure(['messages' => ['*' => ['id', 'type', 'league_id', 'read', 'created_at', 'title', 'body', 'link']], 'more', 'unread'])->json();
    }

    /** A coach asks with the code, the owner approves, the coach takes a bot's club. */
    private function coach(string $name = 'حمزة'): User
    {
        $coach = User::factory()->create(['name' => $name]);
        $id = $this->actingAs($coach)->postJson('/api/v1/leagues/join', ['code' => $this->league['code']])->assertCreated()->json('request.id');
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/requests/{$id}/approve")->assertOk();
        $this->actingAs($coach)->postJson("/api/v1/leagues/{$this->league['id']}/clubs/{$this->botClub($this->league['id'])}/claim")->assertCreated();

        return $coach;
    }

    public function test_a_message_arrives_live_and_reading_it_on_one_screen_reads_it_on_the_other(): void
    {
        Event::fake([MessageReceived::class, MessagesRead::class]);
        $coach = User::factory()->create(['name' => 'حمزة']);
        $this->actingAs($coach)->postJson('/api/v1/leagues/join', ['code' => $this->league['code']])->assertCreated();

        // The owner hears of the request at once, on his own channel.
        Event::assertDispatched(MessageReceived::class, fn ($e) => $e->userId === $this->owner->id && $e->unread === 1
            && $e->broadcastOn()->name === "private-App.Models.User.{$this->owner->id}" && $e->message['type'] === 'join_request'
            && str_contains($e->message['body'], 'حمزة يطلب الانضمام'));
        $box = $this->inbox($this->owner);
        $this->assertSame(1, $box['unread']);
        $this->assertSame("/leagues/{$this->league['id']}", $box['messages'][0]['link']);
        $this->assertFalse($box['messages'][0]['read']);

        // Read on the computer: the phone's copy of the account is told the same moment.
        $this->postJson("/api/v1/messages/{$box['messages'][0]['id']}/read")->assertOk()->assertJsonPath('unread', 0);
        Event::assertDispatched(MessagesRead::class, fn ($e) => $e->userId === $this->owner->id && $e->ids === [$box['messages'][0]['id']] && $e->unread === 0);
        $this->assertTrue($this->inbox($this->owner)['messages'][0]['read']);
        // Another account's message is not there for anyone else.
        $this->actingAs($coach)->postJson("/api/v1/messages/{$box['messages'][0]['id']}/read")->assertNotFound();
    }

    public function test_the_answer_to_a_request_reaches_the_coach(): void
    {
        $coach = User::factory()->create();
        $id = $this->actingAs($coach)->postJson('/api/v1/leagues/join', ['code' => $this->league['code']])->assertCreated()->json('request.id');
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/requests/{$id}/approve")->assertOk();
        $m = $this->inbox($coach)['messages'][0];
        $this->assertSame(['join_approved', "/leagues/{$this->league['id']}/pick"], [$m['type'], $m['link']]);

        $other = User::factory()->create();
        $id = $this->actingAs($other)->postJson('/api/v1/leagues/join', ['code' => $this->league['code']])->assertCreated()->json('request.id');
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/requests/{$id}/reject")->assertOk();
        $this->assertSame('join_rejected', $this->inbox($other)['messages'][0]['type']);
    }

    public function test_the_referee_the_absence_and_the_kick_become_messages(): void
    {
        $coach = $this->coach();
        $club = DB::table('clubs')->where('user_id', $coach->id)->where('league_id', $this->league['id'])->value('id');
        $fixture = DB::table('fixtures')->where('competition', 'league')->where('is_bye', false)
            ->where(fn ($q) => $q->where('home_id', $club)->orWhere('away_id', $club))->orderBy('scheduled_at')->first();
        // The referee, 30 minutes before: to both coaches (the owner's club may be the other side, or a bot).
        Carbon::setTestNow(Carbon::parse($fixture->scheduled_at, 'UTC')->subMinutes(30));
        $this->artisan('matches:prepare')->assertSuccessful();
        $ref = collect($this->inbox($coach)['messages'])->firstWhere('type', 'referee');
        $this->assertNotNull($ref);
        $this->assertSame('/match', $ref['link']);
        $this->assertMatchesRegularExpression('/(متساهل|متوسط|صارم)/u', $ref['body']);
        $bots = DB::table('messages')->where('type', 'referee')->get()->filter(fn ($m) => json_decode($m->payload)->fixture_id === $fixture->id)->count();
        $this->assertSame(collect([$fixture->home_id, $fixture->away_id])->filter(fn ($c) => Inbox::coachOf($c))->count(), $bots);

        // 48 hours without the league after the season starts: a warning.
        Carbon::setTestNow(Carbon::parse(DB::table('seasons')->where('league_id', $this->league['id'])->value('starts_at'), 'UTC')->addHours(49));
        $this->artisan('leagues:start')->assertSuccessful();
        $this->artisan('leagues:absence')->assertSuccessful();
        $warn = collect($this->inbox($coach)['messages'])->firstWhere('type', 'absence_warning');
        $this->assertStringContainsString('48 ساعة', $warn['body']);

        // The owner kicks him with a reason: he reads it.
        $row = DB::table('league_memberships')->where('user_id', $coach->id)->first();
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/members/{$row->id}/kick", ['reason' => 'لا يدخل أبداً'])->assertOk();
        $kicked = collect($this->inbox($coach)['messages'])->firstWhere('type', 'kicked');
        $this->assertStringContainsString('«لا يدخل أبداً»', $kicked['body']);
    }

    public function test_away_three_days_the_coach_is_told_he_left(): void
    {
        $coach = $this->coach();
        Carbon::setTestNow(Carbon::parse(DB::table('seasons')->where('league_id', $this->league['id'])->value('starts_at'), 'UTC')->addDays(3)->addMinute());
        $this->artisan('leagues:start')->assertSuccessful();
        $this->artisan('leagues:absence')->assertSuccessful();
        $left = collect($this->inbox($coach)['messages'])->firstWhere('type', 'left_absent');
        $this->assertNotNull($left);
        $this->assertStringContainsString('الموسم الجديد', $left['body']);
    }

    public function test_paging_reading_all_and_the_private_channel(): void
    {
        foreach (range(1, 35) as $i) {
            Inbox::send($this->owner->id, 'join_rejected', ['league' => "دوري {$i}"]);
        }
        $first = $this->inbox($this->owner);
        $this->assertCount(30, $first['messages']);
        $this->assertTrue($first['more']);
        $this->assertSame('رفض منشئ دوري دوري 35 طلب انضمامك.', $first['messages'][0]['body']);
        $next = $this->getJson('/api/v1/messages?before='.end($first['messages'])['id'])->assertOk()->json();
        $this->assertCount(5, $next['messages']);
        $this->assertFalse($next['more']);
        $this->getJson('/api/v1/messages/unread')->assertOk()->assertJsonPath('unread', 35);
        $this->postJson('/api/v1/messages/read-all')->assertOk()->assertJsonPath('read', 35);
        $this->getJson('/api/v1/messages/unread')->assertJsonPath('unread', 0);

        // Only the account itself listens on its channel (checked by the real broadcaster, not the test's log one).
        config(['broadcasting.default' => 'reverb']);
        $other = User::factory()->create();
        $this->actingAs($other)->postJson('/broadcasting/auth', ['socket_id' => '1.2', 'channel_name' => "private-App.Models.User.{$this->owner->id}"])->assertForbidden();
        $this->getJson('/api/v1/messages')->assertOk()->assertJsonPath('messages', []);
        auth()->forgetGuards();
        $this->getJson('/api/v1/messages')->assertUnauthorized();
    }
}
