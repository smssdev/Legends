<?php

namespace Tests\Feature;

use App\League\CoachSlots;
use App\Models\User;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/**
 * [Sprint 24 B3] The coach's slots: 8 in all, 2 open on day 0 and one more every 10 days of the account's age, or
 * at once for coins, in order and for good; the countdown, and a message for each slot that opens.
 */
class CoachSlotsTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_the_slots_open_with_the_account_age(): void
    {
        $made = Carbon::parse('2026-10-01 08:00:00', 'UTC');
        $at = fn (string $when) => CoachSlots::openAt($made, Carbon::parse($when, 'UTC'));
        $this->assertSame(2, $at('2026-10-01 08:00:00'));
        $this->assertSame(2, $at('2026-10-11 07:59:59'));
        $this->assertSame(3, $at('2026-10-11 08:00:00'));
        $this->assertSame(4, $at('2026-10-21 08:00:00'));
        $this->assertSame(8, $at('2026-11-30 08:00:00'));
        $this->assertSame(8, $at('2027-06-01 08:00:00'));
        $this->assertSame('2026-10-31 08:00:00', CoachSlots::opensAt($made, 5)->toDateTimeString());
        $this->assertSame('2026-10-01 08:00:00', CoachSlots::opensAt($made, 2)->toDateTimeString());
    }

    public function test_a_new_account_takes_two_teams_then_waits_with_a_countdown(): void
    {
        $user = User::factory()->create(['created_at' => GameClock::now()]);
        $this->makeLeague($user);
        $this->makeLeague($user);
        $home = $this->actingAs($user)->getJson('/api/v1/home')->assertOk()->json();
        $this->assertSame(['club', 'club', ...array_fill(0, 6, 'locked')], array_column($home['slots'], 'state'));
        $this->assertSame('2026-11-01T10:00:00Z', $home['slots'][2]['opens_at']);
        $this->assertSame('2026-11-11T10:00:00Z', $home['slots'][3]['opens_at']);
        $this->assertSame('2026-11-01T10:00:00Z', $home['next_slot_at']);
        // Only the first locked slot is bought, at its price.
        $this->assertSame([50, null], [$home['slots'][2]['unlock_coins'], $home['slots'][3]['unlock_coins']]);
        $this->postJson('/api/v1/leagues', $this->settings())->assertConflict()
            ->assertJsonPath('message', 'فتحاتك المفتوحة كلها مشغولة (2). تُفتح فتحتك التالية بعد 10 يوماً.');
        $this->getJson('/api/v1/leagues')->assertJsonPath('max_active_teams', 2)->assertJsonPath('slots_total', 8);

        // Ten days on: the third is open and free, the wait for the fourth half done.
        Carbon::setTestNow('2026-11-01 10:00:00');
        $home = $this->getJson('/api/v1/home')->json();
        $this->assertSame(['club', 'club', 'free', ...array_fill(0, 5, 'locked')], array_column($home['slots'], 'state'));
        $this->assertSame(5000, $home['slots'][3]['progress_bp']);
        $this->makeLeague($user);
    }

    public function test_a_slot_opens_at_once_for_coins_in_order_and_for_good(): void
    {
        $user = User::factory()->create(['created_at' => GameClock::now()]);
        Wallet::post($user->id, 'admin_gift', 120, 'gift:1');
        $this->actingAs($user);
        // An open slot, or one past the eighth, is not one to buy.
        $this->postJson('/api/v1/home/slots/2/unlock')->assertConflict();
        $this->postJson('/api/v1/home/slots/9/unlock')->assertConflict();

        $home = $this->postJson('/api/v1/home/slots/3/unlock')->assertOk()->json();
        $this->assertSame(70, Wallet::balance($user->id));
        $this->assertSame(['free', 'free', 'free', 'locked'], array_slice(array_column($home['slots'], 'state'), 0, 4));
        $this->assertSame(3, $home['slots_open']);
        $this->assertSame(100, $home['slots'][3]['unlock_coins']);
        $this->assertSame(1, DB::table('wallet_transactions')->where('user_id', $user->id)->where('type', 'slot_unlock')->count());
        // A repeated tap pays nothing more.
        $this->postJson('/api/v1/home/slots/3/unlock')->assertConflict();
        $this->assertSame(70, Wallet::balance($user->id));
        // Not enough coins for the fourth: nothing changes.
        $this->postJson('/api/v1/home/slots/4/unlock')->assertConflict();
        $this->assertSame(70, Wallet::balance($user->id));
        $this->assertSame(3, $this->getJson('/api/v1/home')->json('slots_open'));
        // Bought, it stays open for good, and three teams fit.
        Carbon::setTestNow('2026-12-25 10:00:00');
        $this->assertSame(8, $this->getJson('/api/v1/home')->json('slots_open'));
    }

    public function test_the_fifth_with_the_fourth_on_the_way(): void
    {
        $user = User::factory()->create(['created_at' => GameClock::now()->subDays(10)]);
        Wallet::post($user->id, 'admin_gift', 1000, 'gift:1');
        $this->actingAs($user);
        // The third is open by age; the fifth costs the fourth's price and its own.
        $home = $this->postJson('/api/v1/home/slots/5/unlock')->assertOk()->json();
        $this->assertSame(1000 - 100 - 150, Wallet::balance($user->id));
        $this->assertSame(5, $home['slots_open']);
    }

    public function test_each_slot_that_opens_is_announced_once(): void
    {
        $user = User::factory()->create(['created_at' => GameClock::now()]);
        // The first count only counts: no message for the two open from the start.
        $this->artisan('slots:announce')->assertSuccessful();
        $this->assertSame(0, DB::table('messages')->where('user_id', $user->id)->count());
        $this->assertSame(2, (int) DB::table('users')->where('id', $user->id)->value('slots_notified'));

        Carbon::setTestNow('2026-11-01 10:05:00');
        $this->artisan('slots:announce')->assertSuccessful();
        $this->artisan('slots:announce')->assertSuccessful();
        $messages = DB::table('messages')->where('user_id', $user->id)->where('type', 'slot_opened')->get();
        $this->assertCount(1, $messages);
        $this->assertSame(3, json_decode($messages[0]->payload, true)['slot']);
        $this->actingAs($user)->getJson('/api/v1/messages')->assertOk()->assertJsonPath('messages.0.title', 'مبروك! فُتحت فتحة المدرب رقم 3');

        // A slot bought is not announced as opened.
        Wallet::post($user->id, 'admin_gift', 100, 'gift:1');
        $this->postJson('/api/v1/home/slots/4/unlock')->assertOk();
        $this->artisan('slots:announce')->assertSuccessful();
        $this->assertSame(1, DB::table('messages')->where('user_id', $user->id)->where('type', 'slot_opened')->count());
    }
}
