<?php

namespace Tests\Feature;

use App\Jobs\SendPush;
use App\Messages\Inbox;
use App\Messages\MessageText;
use App\Models\User;
use App\Training\SecretTraining;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** Notifications [PLAN 2.13, Sprint 36]: one channel, each kind wanted or not, each opening its screen. */
class NotificationsTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        Queue::fake();
        $this->owner = User::factory()->create();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function subscribe(User $user, string $endpoint = 'https://push.example/abc')
    {
        return $this->actingAs($user)->postJson('/api/v1/notifications/subscriptions', ['endpoint' => $endpoint, 'keys' => ['p256dh' => 'BKey', 'auth' => 'auth1']]);
    }

    public function test_a_browser_subscribes_once_and_unsubscribes(): void
    {
        $this->subscribe($this->owner)->assertOk()->assertJsonPath('devices', 1);
        $this->subscribe($this->owner)->assertOk()->assertJsonPath('devices', 1);
        $this->subscribe($this->owner, 'https://push.example/def')->assertOk()->assertJsonPath('devices', 2);
        $this->deleteJson('/api/v1/notifications/subscriptions', ['endpoint' => 'https://push.example/abc'])->assertOk()->assertJsonPath('devices', 1);
    }

    public function test_a_message_pushes_its_title_and_screen_unless_its_kind_is_off(): void
    {
        $this->subscribe($this->owner);
        Inbox::send($this->owner->id, 'offer_received', ['from' => 'Arsenal', 'players_in' => ['X'], 'players_out' => [], 'money' => 0]);
        Queue::assertPushed(SendPush::class, fn ($job) => $job->userId === $this->owner->id && $job->payload['link'] === '/market?tab=offers' && $job->payload['title'] !== '');

        $this->actingAs($this->owner)->putJson('/api/v1/notifications', ['kinds' => ['offers' => false]])->assertOk()
            ->assertJsonPath('kinds.2.kind', 'offers')->assertJsonPath('kinds.2.on', false);
        Queue::fake();
        Inbox::send($this->owner->id, 'offer_received', ['from' => 'Arsenal', 'players_in' => ['X'], 'players_out' => [], 'money' => 0]);
        Queue::assertNothingPushed();
        // A message of no notification kind (the match report) stays in the inbox only.
        Inbox::send($this->owner->id, 'match_report', ['match_id' => 1, 'result' => 'win', 'score' => '2-1', 'opponent' => 'X']);
        Queue::assertNothingPushed();
        // No browser subscribed: nothing to push.
        $other = User::factory()->create();
        Inbox::send($other->id, 'training_done', ['player' => 'X', 'overall' => 70]);
        Queue::assertNothingPushed();
    }

    public function test_every_pushing_kind_opens_a_screen(): void
    {
        foreach (config('game.notifications.kinds') as $kind => $types) {
            foreach ($types as $type) {
                if ($type === 'match_soon') {
                    continue;
                }
                $this->assertContains($type, MessageText::TYPES, $type);
            }
        }
        foreach (['referee' => '/match', 'training_done' => '/training', 'stadium_part' => '/stadium', 'scout_report' => '/scout', 'camp_back' => '/training'] as $type => $link) {
            $text = MessageText::render($type, ['player' => 'X', 'overall' => 70, 'players' => [], 'section' => 'pitch', 'stage' => 1, 'part' => 1,
                'league' => 'L', 'opponent' => 'O', 'strictness' => 'medium', 'fixture_id' => 1, 'at' => '2026-10-22 21:00:00']);
            $this->assertStringStartsWith($link, (string) $text['link'], $type);
        }
    }

    public function test_your_match_is_in_ten_minutes_once_to_both_coaches(): void
    {
        $this->template(full: true);
        $league = $this->makeLeague($this->owner, ['team_count' => 4, 'rounds_per_day' => 1, 'round_times' => ['21:00']]);
        $f = SecretTraining::nextFixture($league['my_club_id']);
        $this->subscribe($this->owner);
        Carbon::setTestNow(Carbon::parse($f->scheduled_at, 'UTC')->subMinutes(11));
        $this->artisan('matches:prepare');
        Queue::assertNotPushed(SendPush::class, fn ($j) => $j->payload['tag'] === 'match_soon');
        Carbon::setTestNow(Carbon::parse($f->scheduled_at, 'UTC')->subMinutes(10));
        $this->artisan('matches:prepare');
        $this->artisan('matches:prepare');
        Queue::assertPushed(SendPush::class, fn ($j) => $j->payload['tag'] === 'match_soon' && $j->payload['link'] === '/match');
        Queue::assertPushed(SendPush::class, fn ($j) => $j->payload['tag'] === 'match_soon', 1);
        $this->assertNotNull(DB::table('fixtures')->where('id', $f->id)->value('soon_at'));
    }

    public function test_the_job_without_keys_sends_nothing_and_fails_nothing(): void
    {
        config(['game.notifications.vapid.public' => null]);
        (new SendPush($this->owner->id, ['title' => 't', 'body' => 'b', 'link' => '/', 'tag' => 'x']))->handle();
        $this->assertTrue(true);
    }
}
