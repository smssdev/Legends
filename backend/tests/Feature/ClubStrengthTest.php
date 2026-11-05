<?php

namespace Tests\Feature;

use App\League\ClubStrength;
use App\Models\User;
use App\Support\GameClock;
use App\Training\Training;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X98] The team's strength follows its squad: buying, selling and training move it. */
class ClubStrengthTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    private int $mine;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'starts_at' => GameClock::now()->addDay()->toIso8601ZuluString()]);
        $this->mine = $this->league['my_club_id'];
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function strength(): int
    {
        return (int) DB::table('clubs')->where('id', $this->mine)->value('strength_snapshot');
    }

    private function url(string $path): string
    {
        return "/api/v1/leagues/{$this->league['id']}/market{$path}";
    }

    public function test_the_average_of_the_best_18(): void
    {
        $this->assertNull(ClubStrength::of([]));
        $this->assertSame(7050, ClubStrength::of([70, 71]));
        $this->assertSame(8000, ClubStrength::of([...array_fill(0, 18, 80), 40, 40]));
    }

    public function test_a_new_league_keeps_its_strength_from_the_data(): void
    {
        $before = $this->strength();
        ClubStrength::refresh($this->mine);
        $this->assertSame($before, $this->strength());
    }

    public function test_buying_a_star_raises_it_and_selling_him_lowers_it_again(): void
    {
        $before = $this->strength();
        $p = DB::table('players')->where('league_id', $this->league['id'])->whereNull('club_id')->where('in_pool', true)->orderBy('value')->first();
        DB::table('players')->where('id', $p->id)->update(['overall' => 99]);
        $this->actingAs($this->owner)->postJson($this->url('/buy'), ['player_id' => $p->id, 'idempotency_key' => 'b1'])->assertOk();
        $this->assertGreaterThan($before, $this->strength());

        $this->postJson($this->url('/sell'), ['player_id' => $p->id, 'idempotency_key' => 's1'])->assertOk();
        $this->assertSame($before, $this->strength());
    }

    public function test_training_raises_it(): void
    {
        $before = $this->strength();
        $best = DB::table('players')->where('club_id', $this->mine)->orderByDesc('overall')->first();
        DB::transaction(fn () => Training::advance(Training::player((int) $best->id), (int) config('game.training.progress_scale')));
        $this->assertSame(1, (int) DB::table('players')->where('id', $best->id)->value('training_bonus'));
        $this->assertGreaterThan($before, $this->strength());
    }
}
