<?php

namespace Tests\Feature;

use App\Events\ChatMessageSent;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Event;
use Tests\TestCase;

/** [Sprint 50 M8] The quick reactions on a group message: one each, changed or taken back, counted for everyone. */
class ChatReactionsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-11-10 10:00:00');
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_one_reaction_each_changed_or_taken_back(): void
    {
        Event::fake([ChatMessageSent::class]);
        $sara = User::factory()->create(['username' => 'sara']);
        $omar = User::factory()->create(['username' => 'omar']);
        $id = $this->actingAs($sara)->postJson('/api/v1/groups', ['name' => 'الشلة', 'usernames' => ['omar']])->assertCreated()->json('group.id');
        $msg = $this->postJson("/api/v1/groups/{$id}/messages", ['body' => 'مباراة الغد نار'])->assertCreated()->json('message.id');

        $this->actingAs($omar)->postJson("/api/v1/groups/{$id}/messages/{$msg}/reaction", ['reaction' => 'fire'])->assertOk()
            ->assertJsonPath('message.reactions.fire', 1)->assertJsonPath('message.my_reaction', 'fire');
        Event::assertDispatched(ChatMessageSent::class, fn ($e) => ($e->message['reactions']['fire'] ?? 0) === 1 && $e->message['my_reaction'] === null);
        $this->actingAs($sara)->postJson("/api/v1/groups/{$id}/messages/{$msg}/reaction", ['reaction' => 'fire'])->assertJsonPath('message.reactions.fire', 2);
        // A new one takes the old one's place; the same one again takes it back.
        $this->actingAs($omar)->postJson("/api/v1/groups/{$id}/messages/{$msg}/reaction", ['reaction' => 'cup'])
            ->assertJsonPath('message.reactions', ['fire' => 1, 'cup' => 1]);
        $this->postJson("/api/v1/groups/{$id}/messages/{$msg}/reaction", ['reaction' => 'cup'])
            ->assertJsonPath('message.reactions', ['fire' => 1])->assertJsonPath('message.my_reaction', null);
        // Read back with the page, the viewer's own marked.
        $page = $this->actingAs($sara)->getJson("/api/v1/groups/{$id}/messages")->json('messages');
        $this->assertSame('fire', collect($page)->firstWhere('id', $msg)['my_reaction']);
        // Only the four, and only members.
        $this->postJson("/api/v1/groups/{$id}/messages/{$msg}/reaction", ['reaction' => 'heart'])->assertUnprocessable();
        $this->actingAs(User::factory()->create())->postJson("/api/v1/groups/{$id}/messages/{$msg}/reaction", ['reaction' => 'fire'])->assertNotFound();
    }
}
