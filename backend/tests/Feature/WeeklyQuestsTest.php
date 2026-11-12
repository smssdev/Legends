<?php

namespace Tests\Feature;

use App\Models\User;
use App\Support\GameClock;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 20 B5] Weekly quests: progress from what the club did this week, each reward once, a new week anew. */
class WeeklyQuestsTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_a_quest_pays_once_when_done_and_the_big_one_pays_the_club(): void
    {
        Carbon::setTestNow('2026-10-21 10:00:00');   // a Wednesday
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 4, 'starts_at' => '2026-10-24T10:00:00Z']);
        $mine = $league['my_club_id'];
        $url = "/api/v1/leagues/{$league['id']}/quests";

        $view = $this->actingAs($owner)->getJson($url)->assertOk()->assertJsonCount(5, 'quests')
            // [Sprint 59 F1] The fields the app reads through its generated model (openapi.yaml).
            ->assertJsonStructure(['week', 'renews_at', 'quests' => ['*' => ['quest', 'progress', 'target', 'reward', 'complete', 'claimed']]])->json();
        $this->assertSame('2026-10-19', $view['week']);
        $this->postJson("{$url}/claim", ['quest' => 'friendly'])->assertConflict();

        $opponent = DB::table('clubs')->where('league_id', $league['id'])->where('id', '!=', $mine)->value('id');
        Wallet::post($owner->id, 'admin_gift', 5, 'gift:1');
        $this->postJson("/api/v1/leagues/{$league['id']}/friendlies", ['opponent_id' => $opponent, 'idempotency_key' => 'f1'])->assertCreated();
        $coins = Wallet::balance($owner->id);
        $this->getJson($url)->assertJsonPath('quests.0.complete', true);
        $this->postJson("{$url}/claim", ['quest' => 'friendly'])->assertOk()->assertJsonPath('quests.0.claimed', true);
        $this->assertSame($coins + 10, Wallet::balance($owner->id));
        $this->postJson("{$url}/claim", ['quest' => 'friendly'])->assertConflict();

        // Two matches this week without a defeat: the club's money.
        $season = DB::table('seasons')->where('league_id', $league['id'])->value('id');
        foreach ([[2, 0], [1, 1]] as $i => [$h, $a]) {
            DB::table('fixtures')->insert(['season_id' => $season, 'competition' => 'league', 'round' => 90 + $i, 'home_id' => $mine, 'away_id' => $opponent,
                'scheduled_at' => GameClock::now()->subHours(2 + $i), 'status' => 'finished', 'home_goals' => $h, 'away_goals' => $a, 'is_bye' => false,
                'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        }
        $big = collect($this->getJson($url)->json('quests'))->firstWhere('quest', 'unbeaten');
        $this->assertTrue($big['complete']);
        $this->assertGreaterThan(0, $big['reward']['money']);
        $cash = (int) DB::table('clubs')->where('id', $mine)->value('balance');
        $this->postJson("{$url}/claim", ['quest' => 'unbeaten'])->assertOk();
        $this->assertSame($cash + $big['reward']['money'], (int) DB::table('clubs')->where('id', $mine)->value('balance'));

        // Next Monday in Cairo: everything anew.
        Carbon::setTestNow('2026-10-25 22:30:00');
        $fresh = $this->getJson($url)->assertJsonPath('week', '2026-10-26')->json('quests');
        $this->assertFalse($fresh[0]['claimed']);
        $this->assertSame(0, $fresh[0]['progress']);
    }
}
