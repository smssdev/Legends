<?php

namespace Tests\Feature;

use App\League\TacticsBook;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 21 E5.4] The tactics book reads the engine's own table: what each plan beats, and what beats each shape. */
class TacticsBookTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_the_book_follows_the_engine_table(): void
    {
        $engine = ['matchup_bp' => [
            'counter' => [300, 0, -300], 'long_balls' => [200, -100, -100], 'passing' => [-100, 200, -100],
            'wings' => [-200, 0, 200], 'long_shots' => [-200, -100, 300],
        ]];
        $book = TacticsBook::build($engine);
        $counter = collect($book['plans'])->firstWhere('plan', 'counter');
        $this->assertSame(['high'], $counter['beats']);
        $this->assertSame(['low'], $counter['loses_to']);
        $shapes = collect($book['shapes'])->keyBy('shape');
        // A high line is beaten by the counter first, then the long balls; it stops the wings and the shots most.
        $this->assertSame(['counter', 'long'], $shapes['high']['beaten_by']);
        $this->assertEqualsCanonicalizing(['wings', 'shots'], array_slice($shapes['high']['stops'], 0, 2));
        $this->assertSame('passing', $shapes['high']['stops'][2]);
        $this->assertSame(['shots', 'wings'], $shapes['low']['beaten_by']);
        $this->assertSame(['passing'], $shapes['mid']['beaten_by']);
        $this->assertNull($book['mine']);
    }

    public function test_my_tactics_page_carries_the_book_and_my_shape(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1, 'starts_at' => GameClock::now()->toIso8601ZuluString()]);
        $url = "/api/v1/leagues/{$league['id']}/team/tactics";
        $this->actingAs($owner)->getJson($url)->assertOk()->assertJsonCount(5, 'book.plans')->assertJsonCount(3, 'book.shapes')
            ->assertJsonPath('book.mine', 'mid');
        $this->putJson($url, ['pressing' => 90, 'style' => 70, 'trap' => 1])->assertOk();
        $this->getJson($url)->assertJsonPath('book.mine', 'high');
        $this->putJson($url, ['pressing' => 15, 'style' => 20, 'trap' => 0])->assertOk();
        $this->getJson($url)->assertJsonPath('book.mine', 'low');
    }
}
