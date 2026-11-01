<?php

namespace Tests\Feature;

use App\Models\Club;
use App\Models\User;
use App\Season\Career;
use App\Season\CoachRating;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X18] The home screen: eight club slots (Sprint 24), the trophies and the level, the announcements, and the global ranking. */
class HomeDashboardTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_a_new_coach_claims_the_starter_coins_once_from_home(): void
    {
        // [Sprint 30 P6] 25 coins to start, apart from the verification reward, whatever the taps.
        $coach = User::factory()->create();
        $this->actingAs($coach)->getJson('/api/v1/home')->assertOk()->assertJsonPath('starter_gift', ['coins' => 25, 'claimed' => false]);
        $this->postJson('/api/v1/home/starter-gift')->assertOk()->assertJsonPath('coins', 25)->assertJsonPath('starter_gift.claimed', true);
        $this->postJson('/api/v1/home/starter-gift')->assertOk()->assertJsonPath('coins', 25);
        $this->assertSame(25, Wallet::balance($coach->id));
        $this->assertSame('starter', DB::table('wallet_transactions')->where('user_id', $coach->id)->value('type'));
        $this->getJson('/api/v1/home')->assertJsonPath('starter_gift.claimed', true)->assertJsonPath('coach.coins', 25);
    }

    public function test_eight_slots_one_club_one_waiting_and_the_rest_locked(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create(['name' => 'سليمان']);
        $league = $this->makeLeague($owner);
        $other = User::factory()->create();
        $second = $this->makeLeague($other, ['name' => 'دوري الأصدقاء']);
        $this->actingAs($owner)->postJson('/api/v1/leagues/join', ['code' => $second['code']])->assertCreated();

        $home = $this->actingAs($owner)->getJson('/api/v1/home')->assertOk()->json();
        $this->assertSame(range(1, 8), array_column($home['slots'], 'slot'));
        // [Sprint 24 B3] A new account: two open slots, the six others locked until it is older.
        $this->assertSame(['club', 'waiting', ...array_fill(0, 6, 'locked')], array_column($home['slots'], 'state'));
        $this->assertSame(2, $home['slots_open']);
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

    /** [Sprint 25] The rating on the home screen: a win and a loss move it by the opponent's strength; the ranking by points. */
    public function test_the_rating_rises_and_falls_with_the_results(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner);
        $mine = (int) DB::table('clubs')->where('user_id', $owner->id)->value('id');
        $home = $this->actingAs($owner)->getJson('/api/v1/home')->assertOk()->json();
        $this->assertSame(0, $home['coach']['rating']['points']);
        $this->assertSame('prospect', $home['coach']['rating']['tier']['key']);
        $this->assertSame([], $home['coach']['rating']['recent']);
        $this->assertSame(array_keys(config('game.rating.tiers')), array_column($home['rating_tiers'], 'key'));

        $season = DB::table('seasons')->where('league_id', $league['id'])->value('id');
        $fixtures = DB::table('fixtures')->where('season_id', $season)->where('is_bye', false)->whereNotNull('home_id')->whereNotNull('away_id')
            ->where(fn ($q) => $q->where('home_id', $mine)->orWhere('away_id', $mine))->orderBy('scheduled_at')->limit(2)->get();
        $w = config('game.rating');
        $expected = [];
        foreach ($fixtures as $n => $f) {
            $isHome = $f->home_id === $mine;
            [$for, $against] = $n === 0 ? [3, 0] : [0, 1];
            DB::table('fixtures')->where('id', $f->id)->update(['status' => 'finished', 'home_goals' => $isHome ? $for : $against, 'away_goals' => $isHome ? $against : $for,
                'scheduled_at' => GameClock::now()->addMinutes(10 + $n)]);
            $expected[] = CoachRating::delta(['for' => $for, 'against' => $against, 'strength' => (int) DB::table('clubs')->where('id', $mine)->value('strength_snapshot'),
                'opponent_strength' => (int) DB::table('clubs')->where('id', $isHome ? $f->away_id : $f->home_id)->value('strength_snapshot'), 'away' => ! $isHome], $w);
        }
        $this->assertGreaterThan(0, $expected[0]);
        $this->assertLessThan(0, $expected[1]);

        $rating = $this->actingAs($owner)->getJson('/api/v1/home')->assertOk()->json('coach.rating');
        $this->assertSame(max(0, $expected[0] + $expected[1]), $rating['points']);
        $this->assertSame($expected[0], $rating['peak']);
        // Newest first: the loss, then the win; the loss shows what it truly took (never below zero).
        $this->assertSame(['loss', 'win'], array_column($rating['recent'], 'result'));
        $this->assertSame([$rating['points'] - $expected[0], $expected[0]], array_column($rating['recent'], 'delta'));

        // A league title adds its points, and the ranking by points puts the champion first.
        $other = User::factory()->create(['name' => 'البطل']);
        $this->makeLeague($other);
        DB::table('titles')->insert(['league_id' => $league['id'], 'season_id' => $season, 'user_id' => $other->id, 'club_id' => DB::table('clubs')->where('user_id', $other->id)->value('id'),
            'competition' => 'league', 'position' => 1, 'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        $r = $this->actingAs($owner)->getJson('/api/v1/rankings/coaches?by=rating')->assertOk()->json();
        $this->assertSame('rating', $r['by']);
        $this->assertSame([$w['trophies']['league'][1], $rating['points']], array_column(array_column($r['coaches'], 'rating'), 'points'));
        $this->assertSame('البطل', $r['coaches'][0]['coach']['name']);
        $this->assertSame(2, $r['me']['position']);
    }
}
