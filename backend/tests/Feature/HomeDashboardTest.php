<?php

namespace Tests\Feature;

use App\Models\Club;
use App\Models\User;
use App\Season\Career;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X18] The home screen: ten club slots, the trophies and the level, the announcements, and the global ranking. */
class HomeDashboardTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_ten_slots_one_club_one_waiting_and_the_rest_free(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create(['name' => 'سليمان']);
        $league = $this->makeLeague($owner);
        $other = User::factory()->create();
        $second = $this->makeLeague($other, ['name' => 'دوري الأصدقاء']);
        $this->actingAs($owner)->postJson('/api/v1/leagues/join', ['code' => $second['code']])->assertCreated();

        $home = $this->actingAs($owner)->getJson('/api/v1/home')->assertOk()->json();
        $this->assertSame(range(1, 10), array_column($home['slots'], 'slot'));
        $this->assertSame(['club', 'waiting', ...array_fill(0, 8, 'free')], array_column($home['slots'], 'state'));
        $this->assertSame($league['id'], $home['slots'][0]['league']['id']);
        $this->assertNotNull($home['slots'][0]['club']['crest_url']);
        // [UP7] The card shows the club's cash and the coach's coins.
        $this->assertSame((int) Club::find($home['slots'][0]['club']['id'])->balance, $home['slots'][0]['club']['cash']);
        $this->assertSame(Wallet::balance($owner->id), $home['coach']['coins']);
        $this->assertSame('دوري الأصدقاء', $home['slots'][1]['league']['name']);
        $this->assertSame(['total' => 0, 'league' => 0, 'cup' => 0], $home['trophies']);
        $this->assertSame(1, $home['coach']['level']['level']);
        $this->assertSame([], $home['announcements']);
    }

    public function test_the_level_grows_with_wins_and_trophies(): void
    {
        $none = Career::level(['won' => 0, 'drawn' => 0], ['total' => 0]);
        $this->assertSame([1, 0, 20], [$none['level'], $none['xp'], $none['next']]);
        // 6 wins = 18 points: still level 1, at 90%.
        $this->assertSame([1, 9000], array_values(array_intersect_key(Career::level(['won' => 6, 'drawn' => 0], ['total' => 0]), array_flip(['level', 'progress_bp']))));
        // One trophy (30) and 10 wins (30) = 60 points: level 3 (from 60, next at 120).
        $this->assertSame(3, Career::level(['won' => 10, 'drawn' => 0], ['total' => 1])['level']);
    }

    public function test_the_ranking_puts_the_trophies_first(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $a = User::factory()->create(['name' => 'أ']);
        $b = User::factory()->create(['name' => 'ب']);
        $la = $this->makeLeague($a);
        $this->makeLeague($b);
        $season = DB::table('seasons')->where('league_id', $la['id'])->value('id');
        $club = DB::table('clubs')->where('user_id', $b->id)->value('id');
        DB::table('titles')->insert(['league_id' => $la['id'], 'season_id' => $season, 'user_id' => $b->id, 'club_id' => $club, 'competition' => 'cup', 'position' => 1,
            'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);

        $r = $this->actingAs($a)->getJson('/api/v1/rankings/coaches')->assertOk()->json();
        $this->assertSame(['ب', 'أ'], array_column(array_column($r['coaches'], 'coach'), 'name'));
        $this->assertSame(2, $r['me']['position']);
        $this->assertSame(1, $r['coaches'][0]['trophies']['cup']);
        $this->actingAs($a)->getJson('/api/v1/rankings/coaches?by=level')->assertOk()->assertJsonPath('by', 'level');
        $this->actingAs($a)->getJson('/api/v1/rankings/coaches?by=money')->assertStatus(422);
    }
}
