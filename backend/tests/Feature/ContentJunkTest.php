<?php

namespace Tests\Feature;

use App\Messages\Inbox;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/** [X61] The test announcements are listed, and removed with their inbox copies only when the owner asks; [Sprint 30 P3] the rewarded ads too, from the panel. */
class ContentJunkTest extends TestCase
{
    use RefreshDatabase;

    public function test_test_announcements_are_listed_then_removed_on_request_and_real_ones_stay(): void
    {
        $user = User::factory()->create();
        $junk = DB::table('announcements')->insertGetId(['title' => 'tesst', 'body' => 'ytkregekgek', 'sent' => 1, 'created_at' => GameClock::now()]);
        $real = DB::table('announcements')->insertGetId(['title' => 'موسم جديد', 'body' => 'يبدأ الموسم الأحد.', 'sent' => 1, 'created_at' => GameClock::now()]);
        Inbox::send($user->id, 'announcement', ['title' => 'tesst', 'body' => 'ytkregekgek', 'from' => 'x', 'username' => 'x', 'announcement_id' => $junk]);
        Inbox::send($user->id, 'announcement', ['title' => 'موسم جديد', 'body' => 'يبدأ الموسم الأحد.', 'from' => 'x', 'username' => 'x', 'announcement_id' => $real]);

        $this->artisan('content:junk')->assertSuccessful();
        $this->assertSame(2, DB::table('announcements')->count());

        $this->artisan('content:junk --delete-announcements')->assertSuccessful();
        $this->assertSame([$real], DB::table('announcements')->pluck('id')->all());
        $this->assertSame(1, DB::table('messages')->where('type', 'announcement')->count());
    }

    public function test_the_admin_sees_and_removes_test_texts_and_cannot_write_new_ones(): void
    {
        // [Sprint 30 P3] The tester's leftovers in the rewarded ads and the announcements, from the panel.
        $admin = User::factory()->create(['role' => 'admin']);
        $now = GameClock::now();
        $ad = fn (string $title, string $body) => DB::table('house_ads')->insertGetId(['title' => $title, 'body' => $body, 'created_at' => $now, 'updated_at' => $now]);
        $ad('tesst', 'شاهد واربح');
        $ad('عرض الأسبوع', 'slklsklskslkslks');
        $realAd = $ad('عرض الأسبوع', 'شاهد إعلاناً واختصر التدريب.');
        DB::table('announcements')->insert(['title' => 'tesst', 'body' => 'tesst', 'sent' => 0, 'created_at' => $now]);
        $this->withHeader('Referer', config('app.url'));

        $this->actingAs(User::factory()->create())->getJson('/api/v1/admin/junk')->assertForbidden();
        $this->actingAs($admin)->getJson('/api/v1/admin/junk')->assertOk()->assertJsonCount(2, 'house_ads')->assertJsonCount(1, 'announcements');
        $this->postJson('/api/v1/admin/junk/purge')->assertOk()->assertJsonPath('house_ads', 2)->assertJsonPath('announcements', 1);
        $this->assertSame([$realAd], DB::table('house_ads')->pluck('id')->all());
        $this->getJson('/api/v1/admin/junk')->assertJsonCount(0, 'house_ads')->assertJsonCount(0, 'announcements');

        // And a new rewarded ad cannot be a test's.
        $this->postJson('/api/v1/admin/house-ads', ['title' => 'tesst', 'body' => 'شاهد واربح'])->assertJsonValidationErrors('title');
        $this->postJson('/api/v1/admin/house-ads', ['title' => 'عرض', 'body' => 'slklsklskslkslks'])->assertJsonValidationErrors('body');
        $this->patchJson("/api/v1/admin/house-ads/{$realAd}", ['title' => 'test'])->assertJsonValidationErrors('title');
    }
}
