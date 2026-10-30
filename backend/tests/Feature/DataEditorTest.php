<?php

namespace Tests\Feature;

use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X62 E8] The data editor: the admin only, every change logged, a used player not deleted, small leagues flagged. */
class DataEditorTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    public function test_the_admin_corrects_adds_and_removes_data_and_every_change_is_logged(): void
    {
        $this->template(full: true);
        $owner = User::factory()->create();
        $this->makeLeague($owner, ['team_count' => 4, 'starts_at' => GameClock::now()->addDay()->toIso8601ZuluString()]);
        $admin = User::factory()->create(['role' => 'admin']);
        $this->withHeader('Referer', config('app.url'));
        $this->actingAs($owner)->getJson('/api/v1/admin/data?kind=players')->assertForbidden();

        $this->actingAs($admin);
        $used = DB::table('players')->value('master_player_id');
        $name = DB::table('master_players')->where('id', $used)->value('name');
        $rows = $this->getJson('/api/v1/admin/data?kind=players&q='.urlencode(mb_substr($name, 0, 4)))->assertOk()->json('rows');
        $this->assertContains($used, array_column($rows, 'id'));

        // A correction: the age, kept with what it was.
        $age = (int) DB::table('master_players')->where('id', $used)->value('age');
        $this->patchJson("/api/v1/admin/data/players/{$used}", ['age' => $age === 30 ? 31 : 30, 'potential' => 10])->assertJsonValidationErrors('potential');
        $this->patchJson("/api/v1/admin/data/players/{$used}", ['age' => $age === 30 ? 31 : 30])->assertOk();
        $edit = DB::table('data_edits')->where('target_id', $used)->first();
        $this->assertSame(['before' => ['age' => $age], 'after' => ['age' => $age === 30 ? 31 : 30]], json_decode($edit->changes, true));
        $this->assertSame($admin->id, (int) $edit->user_id);
        $this->deleteJson("/api/v1/admin/data/players/{$used}")->assertConflict();

        // A new club and a player in it; the player removed again (no league has him).
        $club = $this->postJson('/api/v1/admin/data/clubs', ['name' => 'نادي الاختبار الجديد', 'code' => 'NEW', 'league_name' => 'دوري جديد',
            'color_primary' => '#112233', 'color_secondary' => '#FFCC00'])->assertCreated()->json('row.id');
        $this->postJson('/api/v1/admin/data/clubs', ['name' => 'test', 'code' => 'TT', 'league_name' => 'x x', 'color_primary' => '#112233', 'color_secondary' => '#FFCC00'])
            ->assertJsonValidationErrors('name');
        $p = $this->postJson('/api/v1/admin/data/players', ['name' => 'Karim Adel', 'position' => 'ST', 'line' => 'att', 'age' => 20, 'overall' => 66,
            'potential' => 78, 'value' => 900000, 'master_club_id' => $club])->assertCreated()->json('row');
        $this->assertSame(66, (int) $p['sho']);
        $this->deleteJson("/api/v1/admin/data/players/{$p['id']}")->assertOk();
        $this->assertSame(['create', 'create', 'delete', 'update'], DB::table('data_edits')->orderBy('action')->pluck('action')->all());

        // The new league has one club: too small for a new league.
        $leagues = collect($this->getJson('/api/v1/admin/data/leagues')->assertOk()->json('leagues'))->keyBy('name');
        $this->assertTrue($leagues['دوري جديد']['too_small']);
    }
}
