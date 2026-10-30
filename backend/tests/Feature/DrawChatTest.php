<?php

namespace Tests\Feature;

use App\Events\DrawChatSent;
use App\Models\User;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X66] The live draw's chat: everyone watching says a line or reacts, live and kept for the replay, around the draw only. */
class DrawChatTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private int $id;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create(['name' => 'المنظم']);
        Wallet::post($this->owner->id, 'daily', 10_000, 'test-grant:'.$this->owner->id);
        $this->id = $this->actingAs($this->owner)->postJson('/api/v1/tournaments', ['template' => 'custom', 'format' => 'groups', 'group_count' => 2,
            'teams' => DB::table('master_clubs')->where('league_name', 'Test League')->pluck('id')->all(),
            'starts_at' => GameClock::now()->addDay()->toIso8601ZuluString(), 'draw_at' => GameClock::now()->addHours(3)->toIso8601ZuluString()])
            ->assertCreated()->json('tournament.id');
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_everyone_watching_talks_and_reacts_around_the_draw_only(): void
    {
        Event::fake([DrawChatSent::class]);
        $fan = User::factory()->create(['name' => 'مشجع']);
        $url = "/api/v1/tournaments/{$this->id}/draw/chat";
        // Three hours before: closed.
        $this->actingAs($fan)->getJson($url)->assertOk()->assertJsonPath('open', false);
        $this->postJson($url, ['kind' => 'text', 'body' => 'مبكراً'])->assertStatus(409);
        // Within the hour before it: open to anyone signed in, not only the tournament's coaches.
        Carbon::setTestNow(GameClock::now()->addHours(2)->addMinutes(30));
        $this->postJson($url, ['kind' => 'text', 'body' => 'البرازيل في الأولى 🔥'])->assertCreated()->assertJsonPath('message.user.name', 'مشجع');
        $this->postJson($url, ['kind' => 'emoji', 'body' => '😱'])->assertCreated();
        $this->postJson($url, ['kind' => 'emoji', 'body' => '💩'])->assertStatus(422);
        Event::assertDispatched(DrawChatSent::class, fn ($e) => $e->leagueId === $this->id && $e->message['body'] === '😱');
        $chat = $this->getJson($url)->assertOk()->json();
        $this->assertTrue($chat['open']);
        $this->assertSame(['text', 'emoji'], array_column($chat['messages'], 'kind'));
        $this->assertContains('🏆', $chat['reactions']);
        // A line said over and over is stopped.
        for ($i = 0; $i < 11; $i++) {
            $this->postJson($url, ['kind' => 'text', 'body' => "رسالة {$i}"]);
        }
        $this->postJson($url, ['kind' => 'text', 'body' => 'زيادة'])->assertStatus(429);
        // The maker deletes a viewer's line; another viewer cannot.
        $first = $chat['messages'][0]['id'];
        $this->actingAs(User::factory()->create())->deleteJson("{$url}/{$first}")->assertForbidden();
        $this->actingAs($this->owner)->deleteJson("{$url}/{$first}")->assertOk();
        $this->assertTrue($this->getJson($url)->json('messages.0.deleted'));
        // Long after the draw: closed, but kept for the replay.
        Carbon::setTestNow(GameClock::now()->addHours(3));
        $this->actingAs($fan)->postJson($url, ['kind' => 'emoji', 'body' => '👏'])->assertStatus(409);
        $this->assertGreaterThan(10, count($this->getJson($url)->json('messages')));
    }

    public function test_the_chat_goes_with_the_admins_retention(): void
    {
        Carbon::setTestNow(GameClock::now()->addHours(2)->addMinutes(30));
        $this->actingAs($this->owner)->postJson("/api/v1/tournaments/{$this->id}/draw/chat", ['kind' => 'emoji', 'body' => '🔥'])->assertCreated();
        Carbon::setTestNow(GameClock::now()->addDays(3));
        $this->artisan('chat:prune', ['--days' => 2])->assertSuccessful();
        $this->assertSame(0, DB::table('draw_chat')->count());
    }
}
