<?php

namespace Tests\Feature;

use App\Events\ChatMessageSent;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 27] Chat groups as in WhatsApp: any coaches, their admins, the live messages, and every league's own group. */
class ChatGroupTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_a_group_with_friends_its_messages_live_and_unread(): void
    {
        Event::fake([ChatMessageSent::class]);
        $sara = User::factory()->create(['name' => 'سارة', 'username' => 'sara']);
        $omar = User::factory()->create(['name' => 'عمر', 'username' => 'omar']);
        $id = $this->actingAs($sara)->postJson('/api/v1/groups', ['name' => 'شلة الكورة', 'usernames' => ['@Omar']])->assertCreated()->json('group.id');
        // Omar is in, and told in his inbox.
        $this->assertSame(1, DB::table('messages')->where('user_id', $omar->id)->where('type', 'chat_invite')->count());
        $this->actingAs($sara)->postJson("/api/v1/groups/{$id}/messages", ['body' => 'مين جاهز للقرعة؟ 🔥'])->assertCreated();
        Event::assertDispatched(ChatMessageSent::class, fn ($e) => $e->groupId === $id && $e->message['body'] === 'مين جاهز للقرعة؟ 🔥');
        $mine = $this->actingAs($omar)->getJson('/api/v1/groups')->assertOk()->json('groups');
        $this->assertSame(1, $mine[0]['unread']);
        $this->assertSame('مين جاهز للقرعة؟ 🔥', $mine[0]['last']['body']);
        // Opening it reads it; a reply quotes what it answers.
        $messages = $this->getJson("/api/v1/groups/{$id}")->assertOk()->json('messages');
        $first = collect($messages)->firstWhere('kind', 'text');
        $this->postJson("/api/v1/groups/{$id}/messages", ['body' => 'أنا', 'reply_to' => $first['id']])->assertCreated()->assertJsonPath('message.reply_to.body', 'مين جاهز للقرعة؟ 🔥');
        $this->assertSame(0, $this->getJson('/api/v1/groups')->json('groups.0.unread'));
        // He deletes his own, not hers.
        $this->deleteJson("/api/v1/groups/{$id}/messages/{$first['id']}")->assertForbidden();
        $reply = DB::table('chat_group_messages')->where('user_id', $omar->id)->value('id');
        $this->deleteJson("/api/v1/groups/{$id}/messages/{$reply}")->assertOk();
        $this->assertTrue(collect($this->getJson("/api/v1/groups/{$id}/messages")->json('messages'))->firstWhere('id', $reply)['deleted']);
        // A stranger sees nothing.
        $this->actingAs(User::factory()->create())->getJson("/api/v1/groups/{$id}")->assertNotFound();
        $this->postJson("/api/v1/groups/{$id}/messages", ['body' => 'hi'])->assertNotFound();
    }

    public function test_admins_add_remove_and_rename_and_a_link_lets_anyone_in(): void
    {
        $admin = User::factory()->create(['username' => 'boss']);
        $member = User::factory()->create(['username' => 'member']);
        $id = $this->actingAs($admin)->postJson('/api/v1/groups', ['name' => 'G', 'usernames' => ['member']])->json('group.id');
        $this->actingAs($member)->patchJson("/api/v1/groups/{$id}", ['name' => 'X'])->assertForbidden();
        $this->postJson("/api/v1/groups/{$id}/members", ['usernames' => ['boss']])->assertForbidden();
        $link = $this->actingAs($admin)->getJson("/api/v1/groups/{$id}")->json('group.invite_url');
        $code = basename($link);
        $guest = User::factory()->create();
        $this->actingAs($guest)->postJson("/api/v1/groups/join/{$code}")->assertOk()->assertJsonPath('group.members_count', 3);
        $this->actingAs($admin)->deleteJson("/api/v1/groups/{$id}/members/{$guest->id}")->assertOk()->assertJsonPath('group.members_count', 2);
        $this->patchJson("/api/v1/groups/{$id}", ['name' => 'الأبطال'])->assertOk()->assertJsonPath('group.name', 'الأبطال');
        // The admin leaves: the member who stays becomes the admin.
        $this->postJson("/api/v1/groups/{$id}/leave")->assertOk();
        $this->assertTrue($this->actingAs($member)->getJson("/api/v1/groups/{$id}")->json('group.is_admin'));
    }

    public function test_a_league_has_its_own_group_of_its_coaches(): void
    {
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['starts_at' => GameClock::now()->addDay()->toIso8601ZuluString()]);
        $coach = $this->approvedCoach($owner, $league);
        $club = DB::table('clubs')->where('league_id', $league['id'])->whereNull('user_id')->value('id');
        $this->actingAs($coach)->postJson("/api/v1/leagues/{$league['id']}/clubs/{$club}/claim")->assertSuccessful();
        $group = $this->actingAs($owner)->getJson("/api/v1/groups/league/{$league['id']}")->assertOk()->json('group');
        $this->assertSame($league['id'], $group['league_id']);
        $this->assertNull($group['invite_url']);
        $this->assertSame(2, $group['members_count']);
        $this->actingAs(User::factory()->create())->getJson("/api/v1/groups/league/{$league['id']}")->assertNotFound();
        $this->actingAs($owner)->postJson("/api/v1/groups/{$group['id']}/leave")->assertStatus(409);
    }
}
