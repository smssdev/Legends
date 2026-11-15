<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Tests\TestCase;

/** [Sprint 15 D1] The app on the site: the admin uploads the APK in pieces; anyone downloads the latest. */
class AppReleaseTest extends TestCase
{
    use RefreshDatabase;

    private string $dir;

    protected function setUp(): void
    {
        parent::setUp();
        $this->dir = sys_get_temp_dir().'/glm-downloads-'.uniqid();
        config(['game.app.downloads_dir' => $this->dir, 'game.app.chunk_kb' => 4]);
        $this->withHeader('Referer', config('app.url'));
    }

    protected function tearDown(): void
    {
        File::deleteDirectory($this->dir);
        parent::tearDown();
    }

    /** Upload these bytes as a release, piece by piece; returns its card. */
    private function upload(User $admin, string $file, string $version)
    {
        $id = $this->actingAs($admin)->postJson('/api/v1/admin/app-releases', ['version' => $version, 'bytes' => strlen($file), 'notes' => 'أول نسخة'])
            ->assertCreated()->json('id');
        foreach (str_split($file, 4096) as $i => $piece) {
            $this->call('PUT', "/api/v1/admin/app-releases/{$id}/chunk?offset=".($i * 4096), [], [], [], ['CONTENT_TYPE' => 'application/octet-stream', 'HTTP_ACCEPT' => 'application/json', 'HTTP_REFERER' => config('app.url')], $piece)
                ->assertOk()->assertJsonPath('received', min(strlen($file), ($i + 1) * 4096));
        }

        return $this->postJson("/api/v1/admin/app-releases/{$id}/finish");
    }

    public function test_the_admin_uploads_the_apk_in_pieces_and_anyone_downloads_the_latest(): void
    {
        $this->getJson('/api/v1/app')->assertOk()->assertJsonPath('android', null);
        $this->get('/api/v1/app/android.apk')->assertNotFound();

        $admin = User::factory()->create(['role' => 'admin']);
        $apk = "PK\x03\x04".random_bytes(10_000);
        $id = $this->actingAs($admin)->postJson('/api/v1/admin/app-releases', ['version' => '0.1.0', 'bytes' => strlen($apk)])->json('id');
        // In order only; a piece sent twice is not added twice.
        $put = fn (int $offset, string $bytes) => $this->call('PUT', "/api/v1/admin/app-releases/{$id}/chunk?offset={$offset}", [], [], [],
            ['CONTENT_TYPE' => 'application/octet-stream', 'HTTP_ACCEPT' => 'application/json', 'HTTP_REFERER' => config('app.url')], $bytes);
        $put(4096, substr($apk, 4096, 4096))->assertStatus(409);
        $put(0, substr($apk, 0, 4096))->assertOk()->assertJsonPath('received', 4096);
        $put(0, substr($apk, 0, 4096))->assertOk()->assertJsonPath('received', 4096);
        $this->postJson("/api/v1/admin/app-releases/{$id}/finish")->assertStatus(409);   // not whole yet
        $put(4096, substr($apk, 4096, 4096))->assertOk();
        $put(8192, substr($apk, 8192))->assertOk()->assertJsonPath('received', strlen($apk));
        $release = $this->postJson("/api/v1/admin/app-releases/{$id}/finish")->assertOk()->json('release');
        $this->assertSame('ready', $release['status']);
        $this->assertSame(hash('sha256', $apk), $release['sha256']);

        // Anyone: the latest, then the file itself.
        auth()->forgetGuards();
        $this->app['auth']->guard('web')->logout();
        $this->getJson('/api/v1/app')->assertOk()->assertJsonPath('android.version', '0.1.0')->assertJsonPath('android.bytes', strlen($apk))->assertJsonPath('ios', null);
        $file = $this->get('/api/v1/app/android.apk')->assertOk();
        $this->assertSame('application/vnd.android.package-archive', $file->headers->get('Content-Type'));
        $this->assertStringContainsString('GameLegendManager-0.1.0.apk', (string) $file->headers->get('Content-Disposition'));
        $this->assertSame($apk, file_get_contents($file->baseResponse->getFile()->getPathname()));
        $this->assertSame(1, (int) DB::table('app_releases')->where('id', $id)->value('downloads'));
    }

    public function test_only_an_apk_is_published_and_the_two_latest_are_kept(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->upload($admin, str_repeat('not a zip', 200), '0.0.9')->assertStatus(422);
        $this->assertSame(0, DB::table('app_releases')->where('status', 'ready')->count());
        foreach (['0.1.0', '0.2.0', '0.3.0'] as $v) {
            $this->upload($admin, "PK\x03\x04".random_bytes(5000), $v)->assertOk();
        }
        $this->getJson('/api/v1/app')->assertJsonPath('android.version', '0.3.0');
        $this->assertSame(['0.3.0', '0.2.0'], DB::table('app_releases')->where('status', 'ready')->orderByDesc('id')->pluck('version')->all());
        $this->assertCount(2, glob($this->dir.'/*.apk'));
        // Not for a coach, and a version is numbers.
        $this->actingAs(User::factory()->create())->postJson('/api/v1/admin/app-releases', ['version' => '1.0.0', 'bytes' => 5000])->assertForbidden();
        $this->actingAs($admin)->postJson('/api/v1/admin/app-releases', ['version' => 'new', 'bytes' => 5000])->assertStatus(422);
    }

    public function test_without_an_upload_the_app_that_ships_with_the_site_is_offered(): void
    {
        $dir = public_path('downloads');
        $made = ! is_dir($dir);
        @mkdir($dir, 0775, true);
        $about = "$dir/android.json";
        $kept = is_file($about) ? file_get_contents($about) : null;
        file_put_contents("$dir/glm-test.apk", 'PK'.str_repeat('x', 2046));
        file_put_contents($about, json_encode(['version' => '9.9.9', 'file' => 'glm-test.apk']));
        try {
            $this->getJson('/api/v1/app')->assertOk()
                ->assertJsonPath('android.version', '9.9.9')->assertJsonPath('android.bytes', 2048)
                ->assertJsonPath('android.url', url('/downloads/glm-test.apk'))->assertJsonPath('android.old_phones_url', null);
            $this->get('/api/v1/app/android.apk')->assertRedirect(url('/downloads/glm-test.apk'));
        } finally {
            @unlink("$dir/glm-test.apk");
            $kept !== null ? file_put_contents($about, $kept) : @unlink($about);
            if ($made) {
                @rmdir($dir);
            }
        }
    }

    /** [Sprint 71 N3, N4, N6] The shipped app's build details, the newer of the two offered, and the panel's warning. */
    public function test_the_newer_app_is_offered_with_its_build_and_the_panel_says_when_it_is_behind_the_code(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->upload($admin, "PK\x03\x04".random_bytes(5000), '2.3.0')->assertOk();
        $pubspec = $this->dir.'/pubspec.yaml';
        file_put_contents($pubspec, "name: glm\nversion: 2.5.0+16\n");
        config(['game.app.pubspec' => $pubspec]);
        $this->actingAs($admin)->getJson('/api/v1/admin/app-releases')->assertOk()
            ->assertJsonPath('code_version', '2.5.0')->assertJsonPath('behind', true)->assertJsonPath('offered.version', '2.3.0');
        $this->getJson('/api/v1/health')->assertOk()->assertJsonPath('latest_app_version', '2.3.0');

        $dir = public_path('downloads');
        $made = ! is_dir($dir);
        @mkdir($dir, 0775, true);
        $about = "$dir/android.json";
        $kept = is_file($about) ? file_get_contents($about) : null;
        file_put_contents("$dir/glm-test.apk", 'PK'.str_repeat('x', 2046));
        file_put_contents($about, json_encode(['version' => '2.5.0', 'build' => 16, 'built_at' => '2026-11-15T10:00:00Z', 'commit' => 'abc1234def', 'file' => 'glm-test.apk']));
        try {
            Cache::flush();
            // The shipped app is newer than the upload: it is the one offered, with what its build wrote.
            $this->getJson('/api/v1/app')->assertOk()->assertJsonPath('android.version', '2.5.0')->assertJsonPath('android.build', 16)
                ->assertJsonPath('android.built_at', '2026-11-15T10:00:00Z')->assertJsonPath('android.published_at', '2026-11-15T10:00:00Z')
                ->assertJsonPath('android.commit', 'abc1234def');
            $this->get('/api/v1/app/android.apk')->assertRedirect(url('/downloads/glm-test.apk'));
            $this->getJson('/api/v1/health')->assertJsonPath('latest_app_version', '2.5.0');
            $this->actingAs($admin)->getJson('/api/v1/admin/app-releases')->assertJsonPath('behind', false);
        } finally {
            @unlink("$dir/glm-test.apk");
            $kept !== null ? file_put_contents($about, $kept) : @unlink($about);
            if ($made) {
                @rmdir($dir);
            }
        }
    }
}
