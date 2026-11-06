<?php

namespace Tests\Feature;

use App\Jobs\SendPush;
use App\Models\User;
use App\Notify\Push;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

/** [Sprint 19 B1] The Android app's pushes by FCM, on the same channel as the browsers'. */
class FcmTest extends TestCase
{
    use RefreshDatabase;

    private string $credentials;

    protected function setUp(): void
    {
        parent::setUp();
        // A service account of our own making: a real RSA key, so the token's signature is really made.
        $key = openssl_pkey_new(['private_key_bits' => 2048, 'private_key_type' => OPENSSL_KEYTYPE_RSA]);
        openssl_pkey_export($key, $pem);
        $this->credentials = tempnam(sys_get_temp_dir(), 'fcm');
        file_put_contents($this->credentials, json_encode(['client_email' => 'push@glm-test.iam.gserviceaccount.com', 'private_key' => $pem, 'project_id' => 'glm-test']));
    }

    protected function tearDown(): void
    {
        @unlink($this->credentials);
        parent::tearDown();
    }

    public function test_the_app_subscribes_by_its_token_and_gets_the_push_with_its_link(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user)->postJson('/api/v1/notifications/subscriptions', ['channel' => 'fcm', 'token' => 'tok-1'])
            ->assertOk()->assertJsonPath('devices', 1)->assertJsonPath('app_enabled', false);
        // Again: the same device, not a second one.
        $this->postJson('/api/v1/notifications/subscriptions', ['channel' => 'fcm', 'token' => 'tok-1'])->assertJsonPath('devices', 1);

        Queue::fake();
        $this->assertTrue(Push::send($user->id, 'stadium_part', 'اكتمل جزء', 'ابدأ التالي', '/stadium'));
        Queue::assertPushed(SendPush::class);

        config(['game.notifications.fcm.credentials' => $this->credentials]);
        Http::fake([
            'oauth2.googleapis.com/*' => Http::response(['access_token' => 'at-1', 'expires_in' => 3600]),
            'fcm.googleapis.com/*' => Http::response(['name' => 'projects/glm-test/messages/1']),
        ]);
        (new SendPush($user->id, ['title' => 'اكتمل جزء', 'body' => 'ابدأ التالي', 'link' => '/stadium', 'tag' => 'stadium_part', 'league' => 8]))->handle();

        Http::assertSent(function (Request $r) {
            if (! str_contains($r->url(), 'fcm.googleapis.com/v1/projects/glm-test/messages:send')) {
                return false;
            }

            return $r->hasHeader('Authorization', 'Bearer at-1') && $r['message']['token'] === 'tok-1'
                && $r['message']['data']['link'] === '/stadium' && $r['message']['data']['league'] === '8' && $r['message']['notification']['title'] === 'اكتمل جزء';
        });
        // The token was signed with the account's key (a JWT of three parts).
        Http::assertSent(fn (Request $r) => str_contains($r->url(), 'oauth2.googleapis.com') && count(explode('.', $r['assertion'])) === 3);
        $this->assertDatabaseHas('push_subscriptions', ['endpoint' => 'tok-1']);
    }

    public function test_a_dead_token_is_forgotten_and_nothing_is_sent_without_the_account(): void
    {
        $user = User::factory()->create();
        DB::table('push_subscriptions')->insert(['user_id' => $user->id, 'channel' => 'fcm', 'endpoint' => 'dead', 'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);

        Http::fake([
            'oauth2.googleapis.com/*' => Http::response(['access_token' => 'at-2']),
            'fcm.googleapis.com/*' => Http::response(['error' => ['status' => 'NOT_FOUND', 'details' => [['errorCode' => 'UNREGISTERED']]]], 404),
        ]);
        (new SendPush($user->id, ['title' => 't', 'body' => 'b', 'link' => '/']))->handle();
        Http::assertNothingSent();
        $this->assertDatabaseHas('push_subscriptions', ['endpoint' => 'dead']);

        config(['game.notifications.fcm.credentials' => $this->credentials]);
        (new SendPush($user->id, ['title' => 't', 'body' => 'b', 'link' => '/']))->handle();
        $this->assertDatabaseMissing('push_subscriptions', ['endpoint' => 'dead']);
    }

    public function test_the_app_gets_its_firebase_settings_only_when_all_are_set(): void
    {
        $this->getJson('/api/v1/app')->assertOk()->assertJsonPath('firebase', null);
        config(['game.notifications.fcm.client' => ['api_key' => 'k', 'app_id' => '1:2:android:3', 'project_id' => 'glm-test', 'sender_id' => '2']]);
        $this->getJson('/api/v1/app')->assertJsonPath('firebase.project_id', 'glm-test');
    }
}
