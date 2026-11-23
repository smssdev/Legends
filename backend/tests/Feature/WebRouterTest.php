<?php

namespace Tests\Feature;

use App\Support\AppPages;
use Tests\TestCase;

/**
 * [Sprint 75 W8, W9] The web server's router (deploy/docker/router.php) on a real PHP server: an address that is no page
 * of the app answers 404 (and noindex) with the app's «not found», a page of the app 200; and ?lang=en sends a public
 * page's English HTML (WEB-08, WEB-09).
 */
class WebRouterTest extends TestCase
{
    /** The app's own list (web/public/app-routes.json), as the server reads it. */
    private function routes(): array
    {
        return json_decode((string) file_get_contents(base_path('../web/public/app-routes.json')), true)['paths'];
    }

    public function test_the_apps_pages_are_known_and_others_are_not(): void
    {
        $routes = $this->routes();
        foreach (['/', '/club', '/club/', '/CLUB', '/leagues', '/leagues/new', '/leagues/12', '/leagues/12/newspaper', '/coaches/3',
            '/tournaments/7/draw', '/live/5', '/live/5/report', '/sim/abc', '/sim/abc/report', '/sim/room', '/sim/room/XY12',
            '/groups/join/abc', '/privacy', '/guide', '/download', '/register', '/reset-password', '/intro'] as $page) {
            $this->assertTrue(AppPages::known($page, $routes), $page);
        }
        foreach (['/definitely-not-a-page-12345', '/leagues/abc', '/leagues/12/nope', '/club/more', '/live/x', '/wp-login.php', '/admin/x/y'] as $page) {
            $this->assertFalse(AppPages::known($page, $routes), $page);
        }
    }

    public function test_an_optional_segment_may_be_left_out(): void
    {
        $this->assertTrue(AppPages::known('/join', ['/join/:code?']));
        $this->assertTrue(AppPages::known('/join/AB12', ['/join/:code?']));
        $this->assertFalse(AppPages::known('/join/AB12/x', ['/join/:code?']));
    }

    public function test_the_router_answers_404_for_no_page_and_english_with_lang_en(): void
    {
        $root = sys_get_temp_dir().'/glm-router-'.uniqid();
        mkdir($root.'/public/register', 0777, true);
        mkdir($root.'/app/Http/Security', 0777, true);
        mkdir($root.'/app/Support', 0777, true);
        copy(app_path('Http/Security/SecurityPolicy.php'), $root.'/app/Http/Security/SecurityPolicy.php');
        copy(app_path('Support/AppPages.php'), $root.'/app/Support/AppPages.php');
        copy(base_path('../deploy/docker/router.php'), $root.'/router.php');
        copy(base_path('../web/public/app-routes.json'), $root.'/public/app-routes.json');
        $page = fn (string $lang, string $title) => "<!doctype html><html lang=\"{$lang}\"><head><title>{$title}</title><meta name=\"robots\" content=\"index, follow\" /></head><body></body></html>";
        file_put_contents($root.'/public/index.html', $page('ar', 'الرئيسية'));
        file_put_contents($root.'/public/index.en.html', $page('en', 'Home'));
        file_put_contents($root.'/public/register/index.html', $page('ar', 'إنشاء حساب'));
        file_put_contents($root.'/public/register/index.en.html', $page('en', 'Create an account'));

        $port = 19000 + random_int(0, 999);
        $server = proc_open([PHP_BINARY, '-S', "127.0.0.1:{$port}", '-t', $root.'/public', $root.'/router.php'], [['pipe', 'r'], ['file', '/dev/null', 'w'], ['file', '/dev/null', 'w']], $pipes);
        $get = function (string $path) use ($port): array {
            $body = @file_get_contents("http://127.0.0.1:{$port}{$path}", false, stream_context_create(['http' => ['ignore_errors' => true]]));

            return [(int) explode(' ', $http_response_header[0] ?? 'HTTP/1.1 0')[1], (string) $body];
        };
        try {
            $up = null;
            for ($i = 0; $i < 50 && $up === null; $i++) {
                usleep(100_000);
                $up = @get_headers("http://127.0.0.1:{$port}/", true) ?: null;
            }
            $this->assertNotNull($up, 'the router answered');

            [$status, $body] = $get('/club');
            $this->assertSame(200, $status);
            $this->assertStringContainsString('content="index, follow"', $body);

            [$status, $body] = $get('/definitely-not-a-page-12345');
            $this->assertSame(404, $status, 'no page of the app');
            $this->assertStringContainsString('<meta name="robots" content="noindex" />', $body);
            $this->assertStringContainsString('<html lang="ar">', $body, "the app's page, which shows «not found»");

            [$status, $body] = $get('/definitely-not-a-page-12345?lang=en');
            $this->assertSame(404, $status);
            $this->assertStringContainsString('<html lang="en">', $body);

            [$status, $body] = $get('/register?lang=en');
            $this->assertSame(200, $status);
            $this->assertStringContainsString('<title>Create an account</title>', $body);
            $this->assertStringContainsString('<title>إنشاء حساب</title>', $get('/register')[1]);
            $this->assertStringContainsString('<title>Home</title>', $get('/?lang=en')[1]);
            $this->assertStringContainsString('<title>الرئيسية</title>', $get('/?lang=ar')[1]);
        } finally {
            proc_terminate($server);
            proc_close($server);
            array_map('unlink', glob($root.'/{,public/,public/register/,app/Http/Security/,app/Support/}*.*', GLOB_BRACE));
        }
    }
}
