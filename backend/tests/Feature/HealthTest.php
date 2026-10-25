<?php

namespace Tests\Feature;

use App\Events\ServerPing;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class HealthTest extends TestCase
{
    public function test_health_tells_the_version_the_oldest_app_and_the_game_time(): void
    {
        $this->getJson('/api/v1/health')->assertOk()
            ->assertJsonPath('status', 'ok')
            ->assertJsonPath('version', config('app.version'))
            ->assertJsonPath('min_app_version', config('game.app.min_version'))
            ->assertJsonPath('engine_version', config('game.engine.version'))
            ->assertJsonPath('broadcast', ['channel' => 'system', 'event' => 'ping'])
            ->assertJsonStructure(['time', 'clock_offset']);
    }

    public function test_ping_broadcasts_the_test_event_on_the_public_system_channel(): void
    {
        Event::fake([ServerPing::class]);
        $this->postJson('/api/v1/health/ping')->assertStatus(202)->assertJsonPath('sent', true);
        Event::assertDispatched(ServerPing::class, fn (ServerPing $e) => $e->broadcastOn()->name === 'system'
            && $e->broadcastAs() === 'ping' && $e->broadcastWith()['message'] === 'البث يعمل');
    }

    public function test_every_api_error_has_one_shape_in_arabic(): void
    {
        $this->getJson('/api/v1/nothing-here')->assertNotFound()
            ->assertExactJson(['message' => 'غير موجود.', 'code' => 'not_found']);

        $this->deleteJson('/api/v1/health')->assertStatus(405)
            ->assertJsonPath('code', 'method_not_allowed')->assertJsonPath('message', 'هذه الطريقة غير مسموحة هنا.');

        Route::middleware('api')->post('/api/v1/_test/validate', fn () => request()->validate(['email' => 'required|email', 'name' => 'required|string|max:5']));
        $this->postJson('/api/v1/_test/validate', ['email' => 'x', 'name' => 'طويل جداً'])->assertStatus(422)
            ->assertJsonPath('code', 'validation')
            ->assertJsonPath('message', 'تحقق من البيانات المدخلة.')
            ->assertJsonPath('errors.email.0', 'اكتب بريداً إلكترونياً صحيحاً.')
            ->assertJsonPath('errors.name.0', 'يجب ألا يزيد الاسم على 5 حرفاً.');

        Route::middleware('api')->get('/api/v1/_test/conflict', fn () => abort(409, 'انتهت المباراة.'));
        $this->getJson('/api/v1/_test/conflict')->assertStatus(409)
            ->assertExactJson(['message' => 'انتهت المباراة.', 'code' => 'conflict']);

        Route::middleware('api')->get('/api/v1/_test/boom', fn () => throw new \RuntimeException('secret detail'));
        config(['app.debug' => false]);
        $this->getJson('/api/v1/_test/boom')->assertStatus(500)
            ->assertExactJson(['message' => 'حدث خطأ غير متوقع، حاول مجدداً.', 'code' => 'server_error']);
    }

    public function test_too_many_pings_get_the_arabic_rate_limit_error(): void
    {
        Event::fake([ServerPing::class]);
        for ($i = 0; $i < 10; $i++) {
            $this->postJson('/api/v1/health/ping')->assertStatus(202);
        }
        $this->postJson('/api/v1/health/ping')->assertStatus(429)
            ->assertJsonPath('code', 'too_many_requests')->assertJsonPath('message', 'طلبات كثيرة، حاول بعد قليل.');
    }

    /** [X13] The support buttons: a WhatsApp link with a ready message, a Telegram link, none when not set. */
    public function test_health_gives_the_support_links_only_when_set(): void
    {
        $this->getJson('/api/v1/health')->assertJsonPath('support', ['whatsapp' => null, 'telegram' => null]);
        config(['game.support.whatsapp' => '+20 100 000 0000', 'game.support.telegram' => '@legends_help']);
        $support = $this->getJson('/api/v1/health')->json('support');
        $this->assertStringStartsWith('https://wa.me/201000000000?text=', $support['whatsapp']);
        $this->assertSame('https://t.me/legends_help', $support['telegram']);
    }
}
