<?php

namespace Tests\Feature;

use App\Data\Crests;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Tests\TestCase;

/** [Sprint 58 B2] The crests as static files: named by their drawing, written again when a club changes. */
class CrestsTest extends TestCase
{
    use RefreshDatabase;

    private string $dir;

    protected function setUp(): void
    {
        parent::setUp();
        // Written beside the real ones would mix them: a folder of the test's own.
        $this->dir = sys_get_temp_dir().'/crests-'.getmypid();
        config(['game.crests.dir' => $this->dir.'/crests', 'game.crests.manifest' => $this->dir.'/crests.json']);
        Crests::forget();
    }

    protected function tearDown(): void
    {
        File::deleteDirectory($this->dir);
        Crests::forget();
        parent::tearDown();
    }

    private function club(string $colour = '#C8102E'): int
    {
        return DB::table('master_clubs')->insertGetId(['data_version' => '2026', 'name' => 'Static FC', 'code' => 'STA', 'league_name' => 'Nowhere League',
            'strength_cp' => 7000, 'color_primary' => $colour, 'color_secondary' => '#FFFFFF']);
    }

    public function test_a_drawn_crest_is_a_static_file_named_by_its_drawing(): void
    {
        $id = $this->club();
        $this->assertStringEndsWith("/api/v1/data/clubs/{$id}/crest.svg", Crests::url($id), 'not written yet: the old route');
        $this->artisan('data:crests')->assertSuccessful();
        $url = Crests::url($id);
        $this->assertMatchesRegularExpression("#/crests/{$id}-[0-9a-f]{10}\\.svg$#", $url);
        $file = $this->dir.parse_url($url, PHP_URL_PATH);
        $this->assertFileExists($file);
        $this->assertStringContainsString('<svg', (string) file_get_contents($file));
        // The old route still answers, for the links already out there.
        $this->get("/api/v1/data/clubs/{$id}/crest.svg")->assertOk();
    }

    public function test_an_edited_club_gets_a_new_crest_name_and_the_old_file_goes(): void
    {
        $id = $this->club();
        Crests::write();
        $before = Crests::url($id);
        $admin = User::factory()->create(['role' => 'admin']);
        $this->withHeader('Referer', config('app.url'));
        $this->actingAs($admin)->patchJson("/api/v1/admin/data/clubs/{$id}", ['color_primary' => '#123456'])->assertOk();
        $after = Crests::url($id);
        $this->assertNotSame($before, $after);
        $this->assertFileDoesNotExist($this->dir.parse_url($before, PHP_URL_PATH));
        $this->assertFileExists($this->dir.parse_url($after, PHP_URL_PATH));
    }
}
