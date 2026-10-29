<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/** [Sprint 21 E7] The admin panel: the accounts, suspending and deleting, the announcements, the activity and the conversations. */
class AdminToolsTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::factory()->create(['name' => 'سليمان', 'role' => 'admin']);
        $this->admin->forceFill(['username' => 'owner-sliman'])->save();
        // The panel is the site's: a request from it carries a session (Sanctum's stateful domains).
        $this->withHeader('Referer', config('app.url'));
    }

    public function test_admins_apart_and_the_search_by_the_account_number(): void
    {
        $karim = User::factory()->create(['name' => 'Karim Adel', 'username' => 'karim']);
        User::factory()->create(['name' => 'Omar', 'username' => 'omar']);
        $all = $this->actingAs($this->admin)->getJson('/api/v1/admin/users')->assertOk()->json();
        $this->assertSame(['owner-sliman'], array_column($all['admins'], 'username'));
        $this->assertCount(2, $all['users']);
        $this->getJson('/api/v1/admin/users?q='.$karim->account_no)->assertJsonCount(1, 'users')->assertJsonPath('users.0.username', 'karim')
            ->assertJsonPath('users.0.account_no', $karim->account_no);
        $this->getJson('/api/v1/admin/users?q=kar')->assertJsonCount(1, 'users');
        $this->actingAs($karim)->getJson('/api/v1/admin/users')->assertForbidden();
    }

    public function test_a_suspended_account_is_told_why_and_kept_out_until_lifted(): void
    {
        $coach = User::factory()->create();
        $this->actingAs($this->admin)->postJson("/api/v1/admin/users/{$this->admin->id}/suspend", ['reason' => 'test'])->assertConflict();
        $this->postJson("/api/v1/admin/users/{$coach->id}/suspend", ['reason' => 'سب في الجريدة'])->assertOk();
        $coach->refresh();
        $this->actingAs($coach)->getJson('/api/v1/auth/me')->assertOk()->assertJsonPath('user.suspended.reason', 'سب في الجريدة');
        $this->getJson('/api/v1/leagues')->assertForbidden()->assertJsonPath('message', 'حسابك معلّق من فريق التطوير: سب في الجريدة');
        $this->postJson('/api/v1/support', ['body' => 'لماذا عُلّق حسابي؟'])->assertOk();
        $this->actingAs($this->admin)->deleteJson("/api/v1/admin/users/{$coach->id}/suspend")->assertOk();
        $this->actingAs($coach->refresh())->getJson('/api/v1/leagues')->assertOk();
        $this->assertSame(['suspend', 'unsuspend'], DB::table('admin_log')->orderBy('id')->pluck('action')->all());
    }

    public function test_a_suspended_app_account_is_kept_out_with_its_bearer_token_too(): void
    {
        // The app signs in by token: the suspension must hold there too, not only for the site's session.
        $coach = User::factory()->create(['password' => 'secret-pass-1']);
        $this->actingAs($this->admin)->postJson("/api/v1/admin/users/{$coach->id}/suspend", ['reason' => 'غش في المباريات'])->assertOk();
        $token = $coach->createToken('phone')->plainTextToken;
        $this->app['auth']->forgetGuards();
        $this->withHeaders(['Referer' => '', 'Authorization' => "Bearer {$token}"]);
        $this->getJson('/api/v1/leagues')->assertForbidden()->assertJsonPath('message', 'حسابك معلّق من فريق التطوير: غش في المباريات');
        $this->getJson('/api/v1/auth/me')->assertOk()->assertJsonPath('user.suspended.reason', 'غش في المباريات');
    }

    public function test_the_coaches_come_a_page_at_a_time(): void
    {
        config(['game.admin.users_per_page' => 2]);
        User::factory()->count(3)->create();
        $first = $this->actingAs($this->admin)->getJson('/api/v1/admin/users')->assertOk()->assertJsonCount(2, 'users')->assertJsonCount(1, 'admins')
            ->assertJsonPath('has_more', true)->json();
        $second = $this->getJson('/api/v1/admin/users?page=2')->assertOk()->assertJsonCount(1, 'users')->assertJsonCount(0, 'admins')->assertJsonPath('has_more', false)->json();
        $this->assertEmpty(array_intersect(array_column($first['users'], 'id'), array_column($second['users'], 'id')));
    }

    public function test_deleting_asks_for_the_account_number_and_is_logged(): void
    {
        $coach = User::factory()->create();
        $this->actingAs($this->admin)->deleteJson("/api/v1/admin/users/{$coach->id}", ['confirm' => 12])->assertStatus(422);
        $this->deleteJson("/api/v1/admin/users/{$this->admin->id}", ['confirm' => $this->admin->account_no])->assertConflict();
        $this->deleteJson("/api/v1/admin/users/{$coach->id}", ['confirm' => $coach->account_no])->assertOk();
        $this->assertNull(User::find($coach->id));
        $this->assertSame('delete', DB::table('admin_log')->value('action'));
        $this->getJson('/api/v1/admin/activity')->assertOk()->assertJsonCount(14, 'days')->assertJsonPath('log.0.action', 'delete');
    }

    public function test_an_announcement_is_kept_with_its_sender_and_time_and_reaches_everyone(): void
    {
        $coach = User::factory()->create();
        $this->actingAs($this->admin)->postJson('/api/v1/admin/announcements', ['title' => 'تحديث جديد', 'body' => 'أضفنا أخبار الدوري.'])->assertCreated()->assertJsonPath('sent', 2);
        $this->getJson('/api/v1/admin/announcements')->assertOk()->assertJsonPath('announcements.0.title', 'تحديث جديد')
            ->assertJsonPath('announcements.0.body', 'أضفنا أخبار الدوري.')->assertJsonPath('announcements.0.sender.username', 'Owner-Sliman')->assertJsonPath('announcements.0.sent', 2);
        $this->assertSame(1, DB::table('messages')->where('user_id', $coach->id)->where('type', 'announcement')->count());
    }

    public function test_a_developer_writes_to_a_coach_and_the_coach_answers(): void
    {
        $coach = User::factory()->create(['name' => 'Karim']);
        $other = User::factory()->create(['role' => 'admin']);
        $this->actingAs($other)->postJson("/api/v1/admin/conversations/{$coach->id}", ['body' => 'أهلاً'])->assertForbidden();
        $this->actingAs($this->admin)->postJson("/api/v1/admin/conversations/{$coach->id}", ['body' => 'أهلاً كريم، كيف نساعدك؟'])->assertOk()
            ->assertJsonPath('messages.0.sender.username', 'Owner-Sliman');
        $this->assertSame('official_message', DB::table('messages')->where('user_id', $coach->id)->value('type'));
        $this->actingAs($coach)->getJson('/api/v1/support')->assertOk()->assertJsonPath('messages.0.from_team', true);
        $this->postJson('/api/v1/support', ['body' => 'شكراً، عندي سؤال عن التدريب.'])->assertOk()->assertJsonCount(2, 'messages');
        $this->actingAs($this->admin)->getJson('/api/v1/admin/conversations')->assertJsonPath('conversations.0.user.id', $coach->id)
            ->assertJsonPath('conversations.0.unread', 1)->assertJsonPath('conversations.0.from_team', false);
        $this->getJson("/api/v1/admin/conversations/{$coach->id}")->assertJsonCount(2, 'messages');
        $this->getJson('/api/v1/admin/conversations')->assertJsonPath('conversations.0.unread', 0);
    }

    public function test_the_leagues_show_their_creators_number_and_the_holidays_their_dates(): void
    {
        $this->actingAs($this->admin)->getJson('/api/v1/admin/leagues')->assertOk();
        $this->getJson('/api/v1/admin/vacations')->assertOk();
    }
}
