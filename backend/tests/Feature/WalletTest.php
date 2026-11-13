<?php

namespace Tests\Feature;

use App\League\MatchResult;
use App\League\MatchRunner;
use App\League\NextFixture;
use App\Models\User;
use App\Support\GameClock;
use App\Training\Training;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** The premium coins, item by item of docs/features/premium.md [Sprint 34]. */
class WalletTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    private int $mine;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function league(bool $fair = false, array $over = []): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'rounds_per_day' => 1, 'round_times' => ['21:00'], 'fair_league' => $fair] + $over);
        $this->mine = $this->league['my_club_id'];
    }

    private function url(string $path): string
    {
        return "/api/v1/leagues/{$this->league['id']}/{$path}";
    }

    public function test_1_each_movement_once_and_never_below_zero(): void
    {
        $this->league();
        $this->assertSame(10, Wallet::post($this->owner->id, 'daily', 10, 'a'));
        $this->assertSame(10, Wallet::post($this->owner->id, 'daily', 10, 'a'));
        $this->assertSame(4, Wallet::post($this->owner->id, 'spy', -6, 'b'));
        try {
            Wallet::post($this->owner->id, 'spy', -5, 'c');
            $this->fail('went below zero');
        } catch (HttpException $e) {
            $this->assertSame('رصيد الكوينز لا يكفي.', $e->getMessage());
        }
        $this->assertSame(4, Wallet::balance($this->owner->id));
        $this->assertSame(4, Wallet::sum($this->owner->id));
    }

    public function test_2_the_daily_reward_once_a_cairo_day(): void
    {
        $this->league();
        $this->actingAs($this->owner)->postJson('/api/v1/wallet/daily')->assertOk()->assertJsonPath('balance', 10)->assertJsonPath('daily.claimed', true)
            // [Sprint 59 F1] The fields the app reads through its generated model (WalletView in openapi.yaml).
            ->assertJsonStructure(['balance', 'cap', 'daily' => ['amount', 'claimed'], 'leagues', 'prices', 'shop' => ['*' => ['coins', 'label']],
                'transactions' => ['*' => ['type', 'label', 'amount', 'balance_after', 'at']]]);
        $this->postJson('/api/v1/wallet/daily')->assertOk()->assertJsonPath('balance', 10);
        // Cairo's next day (22:00 UTC is already tomorrow there).
        Carbon::setTestNow('2026-10-22 22:30:00');
        $this->postJson('/api/v1/wallet/daily')->assertOk()->assertJsonPath('balance', 20);
    }

    public function test_2_a_season_earns_wins_draws_objectives_and_titles(): void
    {
        // The league's own frozen "now" (league() sets the clock to 2026-10-22 10:00), not the real day the tests run.
        $this->league(over: ['is_dev' => true, 'prep_days' => 1, 'starts_at' => '2026-10-22T10:00:00Z']);
        $this->actingAs($this->owner)->postJson($this->url('start'))->assertOk();
        for ($i = 0; $i < 3000 && DB::table('seasons')->where('league_id', $this->league['id'])->where('number', 1)->value('status') === 'running'; $i++) {
            Carbon::setTestNow(GameClock::now()->addSeconds(15));
            $this->artisan('matches:prepare');
            MatchRunner::step();
            $this->artisan('seasons:close');
        }
        $earn = config('game.premium.earn');
        $t = DB::table('wallet_transactions')->where('user_id', $this->owner->id)->get();
        $results = DB::table('fixtures')->where('is_bye', false)->where('status', 'finished')->where('season_id', DB::table('seasons')->where('league_id', $this->league['id'])->where('number', 1)->value('id'))
            ->where(fn ($q) => $q->where('home_id', $this->mine)->orWhere('away_id', $this->mine))->get()
            ->map(fn ($f) => $f->home_id === $this->mine ? $f->home_goals <=> $f->away_goals : $f->away_goals <=> $f->home_goals);
        $this->assertSame($results->filter(fn ($r) => $r === 1)->count() * $earn['win'], (int) $t->where('type', 'win')->sum('amount'));
        $this->assertSame($results->filter(fn ($r) => $r === 0)->count() * $earn['draw'], (int) $t->where('type', 'draw')->sum('amount'));
        $met = DB::table('club_objectives')->where('club_id', $this->mine)->where('achieved', true)->get();
        $this->assertSame($met->sum(fn ($o) => $earn['objective_'.$o->competition]), (int) $t->where('type', 'objective')->sum('amount'));
        $titles = DB::table('titles')->where('club_id', $this->mine)->get();
        $this->assertSame($titles->sum(fn ($x) => $earn[$x->competition.'_'.$x->position] ?? 0), (int) $t->where('type', 'title')->sum('amount'));
        $this->assertSame(Wallet::sum($this->owner->id), Wallet::balance($this->owner->id));
    }

    public function test_3_coins_pay_in_an_open_league_never_in_a_fair_one_and_within_the_cap(): void
    {
        $this->league();
        Wallet::post($this->owner->id, 'daily', 1000, 'seed');
        $money = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        // An open league: coins, and the club's money untouched.
        $this->actingAs($this->owner)->postJson($this->url('spy'))->assertOk()->assertJsonPath('currency', 'coins');
        $this->postJson($this->url('specialists'), ['type' => 'doctor', 'idempotency_key' => 'k'])->assertOk();
        $p = config('game.premium.price');
        $this->assertSame(1000 - $p['spy'] - $p['specialist'], Wallet::balance($this->owner->id));
        $this->assertSame($money, (int) DB::table('clubs')->where('id', $this->mine)->value('balance'));
        // Finish now: a training session.
        $player = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.club_id', $this->mine)
            ->whereColumn('master_players.potential', '>', 'players.overall')->where('master_players.line', 'att')->value('players.id');
        $this->lineCoaches($this->mine);
        Training::add($this->mine, $player);
        $this->postJson($this->url('training/att/finish'))->assertOk();
        $this->assertSame(1, (int) DB::table('training_slots')->value('sessions'));
        // The cap: spending past it is refused.
        DB::table('wallet_transactions')->insert(['user_id' => $this->owner->id, 'type' => 'spy', 'amount' => -350, 'balance_after' => 0, 'idempotency_key' => 'big',
            'league_id' => $this->league['id'], 'season_id' => NextFixture::of($this->mine)->season_id, 'created_at' => GameClock::now()]);
        $this->postJson($this->url('specialists'), ['type' => 'lawyer', 'idempotency_key' => 'k2'])->assertConflict()
            ->assertJsonPath('message', 'بلغت سقف صرف الكوينز في هذا الدوري هذا الموسم (400).');
    }

    public function test_3_a_fair_league_locks_the_coins(): void
    {
        $this->league(fair: true);
        Wallet::post($this->owner->id, 'daily', 1000, 'seed');
        // The features cost club money there, and finishing now is refused.
        $this->actingAs($this->owner)->postJson($this->url('spy'))->assertOk()->assertJsonPath('currency', 'money');
        $this->assertSame(1000, Wallet::balance($this->owner->id));
        $player = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.club_id', $this->mine)
            ->whereColumn('master_players.potential', '>', 'players.overall')->value('players.id');
        $this->lineCoaches($this->mine);
        Training::add($this->mine, $player);
        $line = DB::table('training_slots')->value('line');
        $this->postJson($this->url("training/{$line}/finish"))->assertConflict()->assertJsonPath('message', 'الدوري نزيه: لا تُصرف الكوينز فيه.');
        $this->assertSame(1000, Wallet::balance($this->owner->id));
    }

    public function test_4_no_path_turns_coins_into_club_money(): void
    {
        // Every club-money movement written by the wallet code is a spend (a fair league's price), never a credit.
        foreach (glob(app_path('Wallet/*.php')) as $file) {
            preg_match_all('/ClubLedger::post\(([^;]+)\);/', file_get_contents($file), $calls);
            foreach ($calls[1] as $args) {
                $this->assertMatchesRegularExpression('/^\$\w+, \$\w+, -\$/', $args, basename($file));
            }
        }
        // No route of the API names the coins and club money together as an exchange.
        $routes = collect(app('router')->getRoutes())->map(fn ($r) => $r->uri())->implode(' ');
        foreach (['exchange', 'convert', 'coins-to', 'to-money', 'cash'] as $word) {
            $this->assertStringNotContainsString($word, $routes);
        }
    }

    /** [Sprint 43 C1] A coach beaten by one of a lower rating tier pays a coin; by an equal or higher one, nothing. */
    public function test_5_a_loss_to_a_lower_tier_costs_a_coin(): void
    {
        $this->league();
        $season = (int) DB::table('seasons')->where('league_id', $this->league['id'])->value('id');
        $other = User::factory()->create();
        $theirs = (int) DB::table('clubs')->where('league_id', $this->league['id'])->where('id', '!=', $this->mine)->value('id');
        DB::table('clubs')->where('id', $theirs)->update(['user_id' => $other->id]);
        Wallet::post($this->owner->id, 'daily', 10, 'seed-owner');
        $upset = new \ReflectionMethod(MatchResult::class, 'upsetLoss');
        $fixture = fn (int $id) => (object) ['id' => $id, 'season_id' => $season];

        // Both prospects: an even match, nothing.
        $upset->invoke(null, $fixture(1), $this->mine, $theirs, $this->league['id']);
        $this->assertSame(10, Wallet::balance($this->owner->id));
        // The owner a tier up (a league and a cup title: 160 points): beaten by a prospect, he pays one coin, once.
        foreach (['league' => 1, 'cup' => 1] as $competition => $position) {
            DB::table('titles')->insert(['league_id' => $this->league['id'], 'season_id' => $season, 'user_id' => $this->owner->id, 'club_id' => $this->mine,
                'competition' => $competition, 'position' => $position, 'created_at' => GameClock::now(), 'updated_at' => GameClock::now()]);
        }
        $upset->invoke(null, $fixture(2), $this->mine, $theirs, $this->league['id']);
        $upset->invoke(null, $fixture(2), $this->mine, $theirs, $this->league['id']);
        $this->assertSame(10 - config('game.premium.upset_loss'), Wallet::balance($this->owner->id));
        $this->assertSame(1, DB::table('wallet_transactions')->where('type', 'upset_loss')->count());
        // The prospect beaten by him: nothing.
        Wallet::post($other->id, 'daily', 10, 'seed-other');
        $upset->invoke(null, $fixture(3), $theirs, $this->mine, $this->league['id']);
        $this->assertSame(10, Wallet::balance($other->id));
        // With no coins, nothing to take.
        $empty = User::factory()->create();
        DB::table('clubs')->where('id', $this->mine)->update(['user_id' => $empty->id]);
        $upset->invoke(null, $fixture(4), $this->mine, $theirs, $this->league['id']);
        $this->assertSame(0, Wallet::balance($empty->id));
        $this->assertSame(Wallet::sum($this->owner->id), Wallet::balance($this->owner->id));
    }
}
