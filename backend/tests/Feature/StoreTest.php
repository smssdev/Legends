<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\StoreDealNotice;
use App\Support\GameClock;
use App\Support\Mailer;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

/** [Sprint 43 W2] The store: the admin's packages (they stay) and timed offers, one picture size, bought by WhatsApp. */
class StoreTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-11-05 12:00:00');
        $this->admin = User::factory()->create(['role' => 'admin']);
        $this->withHeader('Referer', config('app.url'));
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function add(array $over = [])
    {
        return $this->actingAs($this->admin)->post('/api/v1/admin/store', $over + ['kind' => 'package', 'title' => 'باقة 1000 كوينز',
            'description' => 'كوينز تكفيك الموسم كله.', 'price' => 150, 'image' => UploadedFile::fake()->image('p.png', 900, 900)], ['Accept' => 'application/json']);
    }

    public function test_the_admin_adds_packages_and_timed_offers_and_coaches_see_them_with_whatsapp(): void
    {
        $package = $this->add()->assertCreated()->json('item');
        $this->assertSame('ج.م', $package['currency']);
        $this->assertNull($package['ends_at']);
        // One picture size: 1280 × 720, whatever was uploaded.
        $pic = $this->get(parse_url($package['image_url'], PHP_URL_PATH))->assertOk();
        $this->assertSame([1280, 720], array_slice(getimagesizefromstring($pic->getContent()), 0, 2));

        // An offer needs its end, and the old price above the price.
        $this->add(['kind' => 'offer', 'title' => 'عرض الشتاء'])->assertStatus(422)->assertJsonValidationErrors('ends_at');
        $this->add(['kind' => 'offer', 'title' => 'عرض', 'old_price' => 100, 'ends_at' => GameClock::now()->addDays(3)->toIso8601ZuluString()])
            ->assertStatus(422)->assertJsonValidationErrors('old_price');
        $offer = $this->add(['kind' => 'offer', 'title' => 'عرض الشتاء', 'price' => 150, 'old_price' => 250, 'currency' => 'USD',
            'ends_at' => GameClock::now()->addDays(3)->toIso8601ZuluString()])->assertCreated()->json('item');
        $this->assertSame(40, $offer['discount']);

        // The coach: the offer first, then the package, each with its WhatsApp chat and his account number.
        $coach = User::factory()->create();
        $items = $this->actingAs($coach)->getJson('/api/v1/store')->assertOk()->json('items');
        $this->assertSame(['offer', 'package'], array_column($items, 'kind'));
        $this->assertStringStartsWith('https://wa.me/201116648302?text=', $items[0]['whatsapp_url']);
        $this->assertStringContainsString((string) $coach->account_no, urldecode($items[0]['whatsapp_url']));

        // The offer goes by itself at its end; the package stays.
        Carbon::setTestNow(GameClock::now()->addDays(3)->addMinute());
        $this->assertSame(['package'], array_column($this->getJson('/api/v1/store')->json('items'), 'kind'));
        $this->assertTrue(collect($this->actingAs($this->admin)->getJson('/api/v1/admin/store')->json('items'))->firstWhere('id', $offer['id'])['ended']);

        // The admin changes the package (no new picture needed), hides it, then deletes it.
        $this->post("/api/v1/admin/store/{$package['id']}", ['kind' => 'package', 'title' => 'باقة 2000 كوينز', 'description' => 'أكثر.', 'price' => 250, 'visible' => '0'],
            ['Accept' => 'application/json'])->assertOk()->assertJsonPath('item.title', 'باقة 2000 كوينز')->assertJsonPath('item.visible', false);
        $this->actingAs($coach)->getJson('/api/v1/store')->assertJsonCount(0, 'items');
        $this->actingAs($this->admin)->deleteJson("/api/v1/admin/store/{$package['id']}")->assertOk();
        $this->assertSame(0, DB::table('store_item_images')->where('store_item_id', $package['id'])->count());
        // Not for a coach.
        $this->actingAs($coach)->postJson('/api/v1/admin/store', [])->assertForbidden();
    }

    public function test_an_offer_goes_by_email_only_to_those_who_asked(): void
    {
        Notification::fake();
        config(['mail.default' => 'smtp', 'mail.mailers.smtp.host' => 'smtp.gmail.com', 'mail.mailers.smtp.password' => 'x']);
        $offer = $this->add(['kind' => 'offer', 'title' => 'عرض', 'ends_at' => GameClock::now()->addDay()->toIso8601ZuluString()])->json('item');
        $wants = User::factory()->create();
        $no = User::factory()->create();
        $this->actingAs($wants)->putJson('/api/v1/notifications', ['email_offers' => true])->assertOk()->assertJsonPath('email_offers', true);
        $this->actingAs($no)->getJson('/api/v1/notifications')->assertJsonPath('email_offers', false);
        $sent = $this->actingAs($this->admin)->postJson("/api/v1/admin/store/{$offer['id']}/email")->assertOk()->json('sent');
        if (Mailer::live()) {
            $this->assertSame(1, $sent);
            Notification::assertSentTo($wants, StoreDealNotice::class, fn ($n) => str_starts_with((string) $n->whatsapp, 'https://wa.me/'));
            Notification::assertNotSentTo($no, StoreDealNotice::class);
        }
        $this->assertNotNull(DB::table('store_items')->where('id', $offer['id'])->value('emailed_at'));
    }
}
