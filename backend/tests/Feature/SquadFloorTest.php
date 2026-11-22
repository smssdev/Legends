<?php

namespace Tests\Feature;

use App\Market\SquadFloor;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X114] A coach's squad keeps 2 keepers, 4 defenders, 4 midfielders and 3 forwards through any sale. */
class SquadFloorTest extends TestCase
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
        // Room over the 16-player floor, so only the lines' floors are tested.
        config(['game.economy.min_squad' => 1]);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function url(string $path): string
    {
        return "/api/v1/leagues/{$this->league['id']}{$path}";
    }

    /** @return int[] my players of a line */
    private function line(string $line): array
    {
        return DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('players.club_id', $this->mine)->where('master_players.line', $line)->orderBy('players.id')->pluck('players.id')->map(fn ($x) => (int) $x)->all();
    }

    public function test_each_line_keeps_its_floor_on_an_instant_sale(): void
    {
        // The full squad: 2 keepers, 5 defenders, 7 midfielders, 4 forwards.
        $this->assertSame(['gk' => 2, 'def' => 5, 'mid' => 7, 'att' => 4], SquadFloor::counts($this->mine));
        $this->actingAs($this->owner);
        $defs = $this->line('def');
        $this->postJson($this->url('/market/sell'), ['player_id' => $defs[0], 'idempotency_key' => 'd1'])->assertOk();
        $this->postJson($this->url('/market/sell'), ['player_id' => $defs[1], 'idempotency_key' => 'd2'])->assertConflict()
            ->assertJsonPath('message', 'لا بد أن يبقى في فريقك 4 مدافعين على الأقل.');
        $att = $this->line('att');
        $this->postJson($this->url('/market/sell'), ['player_id' => $att[0], 'idempotency_key' => 'a1'])->assertOk();
        $this->postJson($this->url('/market/sell'), ['player_id' => $att[1], 'idempotency_key' => 'a2'])->assertConflict()
            ->assertJsonPath('message', 'لا بد أن يبقى في فريقك 3 مهاجمين على الأقل.');
        $this->postJson($this->url('/market/sell'), ['player_id' => $this->line('gk')[0], 'idempotency_key' => 'g1'])->assertConflict();
        $this->assertCount(4, $this->line('def'));
        $this->assertCount(3, $this->line('att'));
    }

    public function test_the_market_says_who_is_held_and_a_listing_is_refused(): void
    {
        $this->actingAs($this->owner);
        $def = $this->line('def')[0];
        $this->postJson($this->url('/market/sell'), ['player_id' => $def, 'idempotency_key' => 'd1'])->assertOk();
        $mine = collect($this->getJson($this->url('/market?source=pool'))->assertOk()->json('mine'))->keyBy('id');
        $this->assertSame('لا بد أن يبقى في فريقك 4 مدافعين على الأقل.', $mine[$this->line('def')[0]]['held']);
        $this->assertSame('لا بد أن يبقى في فريقك 2 حراس مرمى على الأقل.', $mine[$this->line('gk')[0]]['held']);
        $this->assertNull($mine[$this->line('mid')[0]]['held']);
        $p = $mine[$this->line('def')[0]];
        $this->postJson($this->url('/transfers/listings'), ['player_id' => $p['id'], 'price' => $p['value']])->assertConflict()
            ->assertJsonPath('message', 'لا بد أن يبقى في فريقك 4 مدافعين على الأقل.');
    }

    public function test_a_bot_club_is_not_held_by_the_coaches_floor(): void
    {
        $bot = (int) DB::table('clubs')->where('league_id', $this->league['id'])->whereNull('user_id')->value('id');
        $this->assertSame([], SquadFloor::held($bot));
        $def = (int) DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('players.club_id', $bot)->where('master_players.line', 'def')->value('players.id');
        DB::table('players')->where('club_id', $bot)->whereIn('master_player_id', DB::table('master_players')->where('line', 'def')->pluck('id'))->where('id', '!=', $def)->update(['club_id' => null]);
        $this->assertNull(SquadFloor::why($bot, [$def]));
    }
}
