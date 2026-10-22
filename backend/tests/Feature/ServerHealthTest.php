<?php

namespace Tests\Feature;

use App\League\MatchRunner;
use App\Support\GameClock;
use App\Support\ServerHealth;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

/** The home server's health check and its alerts [PLAN 2.19, Sprint 21 B2]. */
class ServerHealthTest extends TestCase
{
    /** @var resource */
    private $reverb;

    private bool $webUp = true;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 20:00:00');
        Cache::flush();
        // Reverb: a real socket listening on a free port.
        $this->reverb = stream_socket_server('tcp://127.0.0.1:0');
        config(['reverb.servers.reverb.host' => '127.0.0.1',
            'reverb.servers.reverb.port' => (int) explode(':', stream_socket_get_name($this->reverb, false))[1],
            'game.monitoring.ntfy_topic' => 'legends-test-topic', 'game.monitoring.web_url' => 'http://127.0.0.1:8000']);
        Http::fake(fn (Request $r) => str_contains($r->url(), '127.0.0.1:8000')
            ? ($this->webUp ? Http::response(['status' => 'ok']) : Http::response('', 500))
            : Http::response(['id' => 'x']));
    }

    protected function tearDown(): void
    {
        fclose($this->reverb);
        Carbon::setTestNow();
        parent::tearDown();
    }

    /** Every service alive, as on a healthy server. */
    private function alive(): void
    {
        MatchRunner::claim('runner');
        Cache::put('heartbeat:queue', GameClock::nowMs(), 3600);
        Cache::put('heartbeat:scheduler', GameClock::nowMs(), 3600);
    }

    private function later(int $seconds): void
    {
        Carbon::setTestNow(GameClock::now()->addSeconds($seconds));
    }

    private function alerts(): array
    {
        return Http::recorded(fn (Request $r) => str_contains($r->url(), 'ntfy.sh'))->map(fn ($p) => $p[0]->body())->values()->all();
    }

    public function test_a_healthy_server_passes_and_alerts_no_one(): void
    {
        $this->alive();
        $this->artisan('server:health --notify')->assertSuccessful();
        $this->assertSame([], $this->alerts());
    }

    public function test_a_killed_match_runner_alerts_the_phones_within_a_minute_once_then_again_and_when_it_comes_back(): void
    {
        $this->alive();
        $this->artisan('server:health --notify')->assertSuccessful();
        // matches:run is killed: its claim (renewed every step) runs out within 10 seconds.
        $this->later(15);
        Cache::put('heartbeat:queue', GameClock::nowMs(), 3600);
        Cache::put('heartbeat:scheduler', GameClock::nowMs(), 3600);
        $this->assertFalse(ServerHealth::check()['matches']['ok']);
        // The watchdog's next run, at most a minute later.
        $this->artisan('server:health --notify')->assertFailed();
        $this->assertCount(1, $this->alerts());
        $this->assertStringContainsString('توقف مشغّل المباريات', $this->alerts()[0]);
        Http::assertSent(fn (Request $r) => $r->url() === 'https://ntfy.sh/legends-test-topic' && $r->header('Priority')[0] === 'urgent');

        // Still down a minute later: no second alert; half an hour later, a reminder.
        $this->later(60);
        $this->artisan('server:health --notify')->assertFailed();
        $this->assertCount(1, $this->alerts());
        $this->later(30 * 60);
        $this->artisan('server:health --notify');
        $this->assertCount(2, $this->alerts());
        $this->assertStringContainsString('ما زال متوقفاً منذ 31 دقيقة', $this->alerts()[1]);

        // Started again: back to normal, and the phones are told.
        $this->alive();
        $this->artisan('server:health --notify')->assertSuccessful();
        $this->assertCount(3, $this->alerts());
        $this->assertStringContainsString('عاد مشغّل المباريات للعمل', $this->alerts()[2]);
    }

    public function test_each_service_is_seen_down(): void
    {
        $this->alive();
        // The queue worker and the scheduler stopped leaving signs of life two and a half minutes ago.
        $this->later(160);
        MatchRunner::claim('runner');
        $checks = ServerHealth::check();
        $this->assertFalse($checks['queue']['ok']);
        $this->assertFalse($checks['scheduler']['ok']);
        $this->assertTrue($checks['matches']['ok']);
        $this->assertTrue($checks['web']['ok']);
        $this->assertTrue($checks['live']['ok']);
        $this->assertTrue($checks['database']['ok']);

        // Reverb and the web stop.
        fclose($this->reverb);
        $this->reverb = stream_socket_server('tcp://127.0.0.1:0');
        config(['reverb.servers.reverb.port' => 1]);
        $this->webUp = false;
        $checks = ServerHealth::check();
        $this->assertFalse($checks['live']['ok']);
        $this->assertFalse($checks['web']['ok']);
    }

    public function test_the_beats_are_written_and_without_a_topic_nothing_is_sent(): void
    {
        config(['game.monitoring.ntfy_topic' => null]);
        ServerHealth::beat('scheduler');
        $this->assertSame(GameClock::nowMs(), Cache::get('heartbeat:scheduler'));
        $this->artisan('server:health --notify')->expectsOutputToContain('لا يوجد NTFY_TOPIC')->assertFailed();
        $this->assertSame([], $this->alerts());
    }
}
