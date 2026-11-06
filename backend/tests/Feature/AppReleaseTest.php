<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
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
}
