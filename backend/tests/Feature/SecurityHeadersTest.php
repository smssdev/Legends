<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
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
            // The groups' voice notes record from this site; the camera and the rest stay closed.
            $r->assertHeader('Permissions-Policy', 'camera=(), microphone=(self), geolocation=(), payment=(), usb=()');
            // [Sprint 51 B2] The full policy, report-only for now, with its reports' address.
            $full = (string) $r->headers->get('Content-Security-Policy-Report-Only');
            $this->assertStringContainsString("default-src 'self'", $full);
            $this->assertStringContainsString('script-src ', $full);
            $this->assertStringNotContainsString("'unsafe-inline' https://www.googletagmanager", $full, 'scripts by hash, never unsafe-inline');
            $this->assertStringContainsString('report-uri /api/v1/csp-report', $full);
            $this->assertFalse($r->headers->has('X-Powered-By'));
        }
        $this->get('https://localhost/api/v1/health')->assertHeader('Strict-Transport-Security');
    }

    /** [Sprint 51 B1] The web server's router sends the game's page before Laravel: the same headers, by hash for its inline scripts. */
    public function test_the_router_serves_the_page_with_the_security_headers(): void
    {
        $root = sys_get_temp_dir().'/glm-router-'.uniqid();
        mkdir($root.'/public', 0777, true);
        mkdir($root.'/app/Http/Security', 0777, true);
        mkdir($root.'/app/Support', 0777, true);
        copy(app_path('Http/Security/SecurityPolicy.php'), $root.'/app/Http/Security/SecurityPolicy.php');
        copy(app_path('Support/AppPages.php'), $root.'/app/Support/AppPages.php');
        copy(base_path('../deploy/docker/router.php'), $root.'/router.php');
        $theme = "try { document.documentElement.classList.add('x') } catch (e) {}";
        file_put_contents($root.'/public/index.html', "<!doctype html><html><head><script>{$theme}</script><script type=\"application/ld+json\">{}</script></head><body></body></html>");
        file_put_contents($root.'/public/app.js', 'console.log(1)');
        @mkdir($root.'/public/logos');
        @mkdir($root.'/public/assets');
        file_put_contents($root.'/public/logos/club.svg', '<svg/>');
        file_put_contents($root.'/public/assets/index-abc123.js', 'console.log(2)');

        $port = 18000 + random_int(0, 999);
        $server = proc_open([PHP_BINARY, '-S', "127.0.0.1:{$port}", '-t', $root.'/public', $root.'/router.php'], [['pipe', 'r'], ['file', '/dev/null', 'w'], ['file', '/dev/null', 'w']], $pipes);
        try {
            $headers = null;
            for ($i = 0; $i < 50 && $headers === null; $i++) {
                usleep(100_000);
                $headers = @get_headers("http://127.0.0.1:{$port}/club", true, stream_context_create(['http' => ['header' => "X-Forwarded-Proto: https\r\n"]])) ?: null;
            }
            $this->assertNotNull($headers, 'the router answered');
            $this->assertSame('nosniff', $headers['X-Content-Type-Options']);
            $this->assertSame('SAMEORIGIN', $headers['X-Frame-Options']);
            $this->assertStringContainsString('max-age=31536000', $headers['Strict-Transport-Security']);
            $this->assertStringContainsString('microphone=(self)', $headers['Permissions-Policy']);
            $this->assertArrayNotHasKey('X-Powered-By', $headers);
            $hash = 'sha256-'.base64_encode(hash('sha256', $theme, true));
            $this->assertStringContainsString("'{$hash}'", $headers['Content-Security-Policy-Report-Only'], 'the theme script by its hash');
            $this->assertSame(1, substr_count($headers['Content-Security-Policy-Report-Only'], "'sha256-"), 'not the JSON-LD block');

            $file = get_headers("http://127.0.0.1:{$port}/app.js", true);
            $this->assertSame('nosniff', $file['X-Content-Type-Options'], 'the built files too');

            // [Sprint 58 B3] A hashed name a year; a fixed name whose content may change an hour, then its ETag (a 304).
            $this->assertSame('public, max-age=31536000, immutable', get_headers("http://127.0.0.1:{$port}/assets/index-abc123.js", true)['Cache-Control']);
            $logo = get_headers("http://127.0.0.1:{$port}/logos/club.svg", true);
            $this->assertSame('public, max-age=3600', $logo['Cache-Control']);
            $again = get_headers("http://127.0.0.1:{$port}/logos/club.svg", true, stream_context_create(['http' => ['header' => "If-None-Match: {$logo['ETag']}\r\n"]]));
            $this->assertStringContainsString('304', $again[0]);
        } finally {
            proc_terminate($server);
            proc_close($server);
            array_map('unlink', glob($root.'/{,public/,public/logos/,public/assets/,app/Http/Security/,app/Support/}*.*', GLOB_BRACE));
        }
    }

    public function test_the_browser_reports_a_csp_violation_without_a_session(): void
    {
        $report = ['csp-report' => ['document-uri' => 'https://example.test/club?secret=1', 'effective-directive' => 'script-src-elem', 'blocked-uri' => 'https://evil.test/x.js?q=1']];
        Log::shouldReceive('warning')->once()->withArgs(fn ($m, $c) => $m === 'csp' && $c['blocked'] === 'https://evil.test/x.js' && $c['page'] === 'https://example.test/club' && $c['directive'] === 'script-src-elem');
        $this->call('POST', '/api/v1/csp-report', [], [], [], ['CONTENT_TYPE' => 'application/csp-report', 'HTTP_ORIGIN' => config('app.url')], json_encode($report))->assertNoContent();
    }

    public function test_the_api_is_not_open_to_other_sites(): void
    {
        $r = $this->get('/api/v1/health', ['Origin' => 'https://example.com']);
        $this->assertNotSame('*', $r->headers->get('Access-Control-Allow-Origin'));
        $this->assertNotSame('https://example.com', $r->headers->get('Access-Control-Allow-Origin'));
        $own = $this->get('/api/v1/health', ['Origin' => rtrim((string) config('app.url'), '/')]);
        $this->assertSame(rtrim((string) config('app.url'), '/'), $own->headers->get('Access-Control-Allow-Origin'));
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
