<?php

namespace Tests\Feature;

use App\Events\ChatMessageSent;
use App\Models\User;
use App\Support\GameClock;
use App\Support\GameSettings;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 29] Chat groups as in WhatsApp: any coaches, their admins, the live messages, and every league's own group. */
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

    /** [X65] Pictures and voice notes, for the group's members only; and the admin may stop them. */
    public function test_pictures_and_voice_notes_reach_the_members_only(): void
    {
        $sara = User::factory()->create(['username' => 'sara']);
        $omar = User::factory()->create(['username' => 'omar']);
        $id = $this->actingAs($sara)->postJson('/api/v1/groups', ['name' => 'G', 'usernames' => ['omar']])->json('group.id');
        $photo = UploadedFile::fake()->image('goal.png', 2000, 1000);
        $m = $this->post("/api/v1/groups/{$id}/media", ['kind' => 'image', 'file' => $photo, 'caption' => 'الهدف!'], ['Accept' => 'application/json'])
            ->assertCreated()->json('message');
        $this->assertSame('image', $m['kind']);
        $this->assertSame('الهدف!', $m['body']);
        $pic = $this->actingAs($omar)->get($m['media_url'])->assertOk();
        $this->assertSame('image/jpeg', $pic->headers->get('Content-Type'));
        [$w] = getimagesizefromstring($pic->getContent());
        $this->assertSame((int) config('game.chat.image_px'), $w);
        $voice = UploadedFile::fake()->createWithContent('voice.webm', random_bytes(4000))->mimeType('audio/webm');
        $v = $this->post("/api/v1/groups/{$id}/media", ['kind' => 'audio', 'file' => $voice, 'seconds' => 7], ['Accept' => 'application/json'])->assertCreated()->json('message');
        $this->assertSame(7, $v['seconds']);
        $this->assertSame('audio/webm', $this->get($v['media_url'])->assertOk()->headers->get('Content-Type'));
        // Not a sound: refused.
        $this->post("/api/v1/groups/{$id}/media", ['kind' => 'audio', 'file' => UploadedFile::fake()->create('x.exe', 5, 'application/x-msdownload')], ['Accept' => 'application/json'])->assertStatus(422);
        // A stranger cannot fetch it; a deleted voice note is gone.
        $this->actingAs(User::factory()->create())->get($v['media_url'])->assertNotFound();
        $this->actingAs($omar)->deleteJson("/api/v1/groups/{$id}/messages/{$v['id']}")->assertOk();
        $this->assertSame(1, DB::table('chat_media')->count());
        // The admin stops media.
        GameSettings::set('chat.media', false);
        $this->post("/api/v1/groups/{$id}/media", ['kind' => 'image', 'file' => UploadedFile::fake()->image('a.png')], ['Accept' => 'application/json'])->assertForbidden();
    }

    /** [X65] The admin keeps the messages so many days; older ones go every hour, their pictures with them. */
    public function test_a_reported_message_reaches_the_admins_queue_and_a_ban_keeps_its_writer_out(): void
    {
        // [Sprint 30 G6] Two members report a message once each; the admin removes it and keeps its writer out.
        Event::fake([ChatMessageSent::class]);
        $sara = User::factory()->create(['username' => 'sara']);
        $omar = User::factory()->create(['username' => 'omar']);
        $ali = User::factory()->create(['username' => 'ali']);
        $id = $this->actingAs($sara)->postJson('/api/v1/groups', ['name' => 'شلة الكورة', 'usernames' => ['omar', 'ali']])->assertCreated()->json('group.id');
        $bad = $this->actingAs($omar)->postJson("/api/v1/groups/{$id}/messages", ['body' => 'كلام مسيء'])->assertCreated()->json('message.id');
        $this->postJson("/api/v1/groups/{$id}/messages/{$bad}/report", ['reason' => 'abuse'])->assertUnprocessable();   // not his own
        $this->actingAs($sara)->postJson("/api/v1/groups/{$id}/messages/{$bad}/report", ['reason' => 'abuse', 'note' => 'سب'])->assertOk();
        $this->postJson("/api/v1/groups/{$id}/messages/{$bad}/report", ['reason' => 'abuse'])->assertOk();          // once is enough
        $this->actingAs($ali)->postJson("/api/v1/groups/{$id}/messages/{$bad}/report", ['reason' => 'spam'])->assertOk();
        $this->postJson("/api/v1/groups/{$id}/messages/{$bad}/report", ['reason' => 'whatever'])->assertUnprocessable();
        $this->actingAs(User::factory()->create())->postJson("/api/v1/groups/{$id}/messages/{$bad}/report", ['reason' => 'abuse'])->assertNotFound();   // not a member: not even there

        $admin = User::factory()->create(['role' => 'admin']);
        $this->withHeader('Referer', config('app.url'));
        $queue = $this->actingAs($admin)->getJson('/api/v1/admin/reports')->assertOk()->json('reports');
        $this->assertCount(1, $queue);
        $this->assertSame(2, $queue[0]['reports']);
        $this->assertSame(['abuse' => 1, 'spam' => 1], $queue[0]['reasons']);
        $this->postJson("/api/v1/admin/reports/{$bad}/decide", ['action' => 'ban'])->assertOk()->assertJsonCount(0, 'reports');
        $this->assertNotNull(DB::table('chat_group_messages')->where('id', $bad)->value('deleted_at'));
        $this->actingAs($omar)->postJson("/api/v1/groups/{$id}/messages", ['body' => 'مرحبا'])->assertForbidden();
        $this->assertSame(1, DB::table('admin_log')->where('action', 'report_ban')->where('target_user_id', $omar->id)->count());
        // Let back in.
        $this->actingAs($admin)->deleteJson("/api/v1/admin/users/{$omar->id}/chat-ban")->assertOk();
        $this->actingAs($omar)->postJson("/api/v1/groups/{$id}/messages", ['body' => 'آسف'])->assertCreated();
    }

    public function test_an_admins_scope_opens_its_sections_only_and_only_a_full_admin_gives_scopes(): void
    {
        // [Sprint 30 G6] support sees the reports and the accounts, not the coins; finance the coins, not the reports.
        $owner = User::factory()->create(['role' => 'admin']);
        $helper = User::factory()->create(['role' => 'admin']);
        $this->withHeader('Referer', config('app.url'));
        $this->actingAs($owner)->putJson("/api/v1/admin/users/{$helper->id}/scope", ['scope' => 'support'])->assertOk()->assertJsonPath('scope', 'support');
        $this->actingAs($helper->fresh())->getJson('/api/v1/admin/reports')->assertOk();
        $this->getJson('/api/v1/admin/users')->assertOk();
        $this->postJson('/api/v1/admin/coins', ['account_no' => 1, 'amount' => 5, 'reason' => 'x', 'idempotency_key' => 'k'])->assertForbidden();
        $this->getJson('/api/v1/admin/2fa')->assertOk()->assertJsonPath('scope', 'support');
        $this->putJson("/api/v1/admin/users/{$owner->id}/scope", ['scope' => 'finance'])->assertForbidden();
        $this->actingAs($owner)->putJson("/api/v1/admin/users/{$helper->id}/scope", ['scope' => 'finance'])->assertOk();
        $this->actingAs($helper->fresh())->getJson('/api/v1/admin/reports')->assertForbidden();
        $this->actingAs($owner)->putJson("/api/v1/admin/users/{$helper->id}/scope", ['scope' => null])->assertOk()->assertJsonPath('scope', null);
    }

    public function test_old_messages_go_after_the_admins_retention(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $sara = User::factory()->create();
        $id = $this->actingAs($sara)->postJson('/api/v1/groups', ['name' => 'G'])->json('group.id');
        $this->postJson("/api/v1/groups/{$id}/messages", ['body' => 'قديمة'])->assertCreated();
        $this->post("/api/v1/groups/{$id}/media", ['kind' => 'image', 'file' => UploadedFile::fake()->image('a.png')], ['Accept' => 'application/json'])->assertCreated();
        Carbon::setTestNow(GameClock::now()->addDays(3));
        $this->postJson("/api/v1/groups/{$id}/messages", ['body' => 'جديدة'])->assertCreated();
        // Kept while the retention is 0.
        $this->artisan('chat:prune')->assertSuccessful();
        $this->assertSame(4, DB::table('chat_group_messages')->count());
        $this->withHeader('Referer', config('app.url'))->actingAs($admin);
        $this->putJson('/api/v1/admin/chat', ['retention_days' => 2, 'media' => true])->assertOk()->assertJsonPath('retention_days', 2);
        $this->actingAs($sara)->putJson('/api/v1/admin/chat', ['retention_days' => 1, 'media' => true])->assertForbidden();
        $this->artisan('chat:prune')->assertSuccessful();
        $this->assertSame(['جديدة'], DB::table('chat_group_messages')->pluck('body')->all());
        $this->assertSame(0, DB::table('chat_media')->count());
    }
}
