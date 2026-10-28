<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** E1: security headers on every answer, big JSON gzipped, and the busy pages read their data in few queries. */
class SecurityHeadersTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    public function test_every_answer_has_the_security_headers(): void
    {
        foreach (['/api/v1/health', '/', '/api/v1/nothing-here'] as $url) {
            $r = $this->get($url);
            $r->assertHeader('X-Content-Type-Options', 'nosniff')->assertHeader('X-Frame-Options', 'SAMEORIGIN')
                ->assertHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
            $this->assertStringContainsString("object-src 'none'", $r->headers->get('Content-Security-Policy'));
            $this->assertStringContainsString("frame-ancestors 'self'", $r->headers->get('Content-Security-Policy'));
            $this->assertFalse($r->headers->has('Strict-Transport-Security'), 'HSTS only behind https');
        }
        $this->get('https://localhost/api/v1/health')->assertHeader('Strict-Transport-Security');
    }

    public function test_big_json_is_gzipped_when_asked_and_small_json_is_not(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(20, full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 20]);
        $this->actingAs($owner)->postJson("/api/v1/leagues/{$league['id']}/start")->assertOk();

        $plain = $this->actingAs($owner)->getJson("/api/v1/leagues/{$league['id']}/fixtures")->assertOk();
        $this->assertFalse($plain->headers->has('Content-Encoding'));
        $zipped = $this->actingAs($owner)->getJson("/api/v1/leagues/{$league['id']}/fixtures", ['Accept-Encoding' => 'gzip, br']);
        $zipped->assertHeader('Content-Encoding', 'gzip');
        $this->assertStringContainsString('Accept-Encoding', $zipped->headers->get('Vary'));
        $this->assertSame($plain->getContent(), gzdecode($zipped->getContent()));
        $this->assertLessThan(strlen($plain->getContent()) / 5, strlen($zipped->getContent()));

        $small = $this->actingAs($owner)->getJson('/api/v1/auth/me', ['Accept-Encoding' => 'gzip']);
        $this->assertFalse($small->headers->has('Content-Encoding'));
        Carbon::setTestNow();
    }

    public function test_the_market_and_the_clubs_read_in_few_queries(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(20, full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 20]);
        $this->actingAs($owner)->postJson("/api/v1/leagues/{$league['id']}/start")->assertOk();
        foreach (["leagues/{$league['id']}/market?source=bots" => 30, "leagues/{$league['id']}/market" => 30, "leagues/{$league['id']}/clubs" => 20] as $url => $most) {
            DB::flushQueryLog();
            DB::enableQueryLog();
            $this->actingAs($owner)->getJson("/api/v1/{$url}")->assertOk();
            $this->assertLessThanOrEqual($most, count(DB::getQueryLog()), $url."\n".implode("\n", array_map(fn ($q) => $q['query'], DB::getQueryLog())));
            DB::disableQueryLog();
        }
        Carbon::setTestNow();
    }
}
