<?php

namespace Tests\Feature;

use App\Messages\Inbox;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/** [X61] The test announcements are listed, and removed with their inbox copies only when the owner asks. */
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
}
