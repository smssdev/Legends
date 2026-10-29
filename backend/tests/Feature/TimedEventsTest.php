<?php

namespace Tests\Feature;

use App\Market\Buyer;
use App\Market\Market;
use App\Market\Pool;
use App\Models\User;
use App\Support\GameClock;
use App\TimedEvents\TimedEvents;
use App\Training\Gain;
use App\Training\Training;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/**
 * [Sprint 23] The admin's timed events: set from the admin panel with a start and an end, in every league or one,
 * never permanent; transfer madness, extreme progression, the market's discount, and the special players.
 */
class TimedEventsTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private User $admin;

    private array $league;

    private int $mine;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->admin = User::factory()->create(['role' => 'admin']);
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'starts_at' => GameClock::now()->addDays(2)->toIso8601ZuluString()]);
        $this->mine = $this->league['my_club_id'];
        $this->lineCoaches($this->mine);
        // The panel is the site's: a request from it carries a session.
        $this->withHeader('Referer', config('app.url'));
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function event(array $body)
    {
        return $this->actingAs($this->admin)->postJson('/api/v1/admin/events', $body);
    }

    private function hours(int $h): string
    {
        return GameClock::now()->copy()->addHours($h)->toIso8601ZuluString();
    }

    public function test_only_the_admin_sets_an_event_and_never_a_permanent_one(): void
    {
        $this->actingAs($this->owner)->postJson('/api/v1/admin/events', ['kind' => 'madness', 'ends_at' => $this->hours(5)])->assertForbidden();
        $this->event(['kind' => 'madness', 'ends_at' => $this->hours(24 * 15)])->assertStatus(422)->assertJsonPath('message', 'الفعالية مؤقتة: 14 أيام على الأكثر.');
        $this->event(['kind' => 'madness', 'ends_at' => $this->hours(-1)])->assertStatus(422);
        $this->event(['kind' => 'progression', 'ends_at' => $this->hours(5), 'power' => 90000])->assertStatus(422);
        $this->event(['kind' => 'nothing', 'ends_at' => $this->hours(5)])->assertStatus(422);
        $id = $this->event(['kind' => 'madness', 'ends_at' => $this->hours(5)])->assertCreated()
            ->assertJsonPath('event.state', 'running')->assertJsonPath('event.power', 20000)->assertJsonPath('event.league', null)->json('event.id');
        $later = $this->event(['kind' => 'discount', 'league_id' => $this->league['id'], 'starts_at' => $this->hours(2), 'ends_at' => $this->hours(6)])
            ->assertCreated()->assertJsonPath('event.state', 'upcoming')->assertJsonPath('event.league.id', $this->league['id'])->json('event.id');
        $this->getJson('/api/v1/admin/events')->assertOk()->assertJsonCount(2, 'events')->assertJsonPath('kinds.legends.price_bp', 15000);
        $this->patchJson("/api/v1/admin/events/{$id}", ['power' => 30000])->assertOk()->assertJsonPath('event.power', 30000);

        // One not started yet is deleted; one running ends now, and stays as a record.
        $this->deleteJson("/api/v1/admin/events/{$later}")->assertOk()->assertJsonPath('deleted', true);
        $this->deleteJson("/api/v1/admin/events/{$id}")->assertOk()->assertJsonPath('deleted', false);
        $this->assertSame(1, DB::table('timed_events')->count());
        $this->assertSame([], TimedEvents::active($this->league['id']));
        $this->deleteJson("/api/v1/admin/events/{$id}")->assertConflict();
    }

    public function test_an_event_runs_from_its_start_to_its_end_in_its_league_only(): void
    {
        $other = $this->makeLeague(User::factory()->create(), ['team_count' => 4, 'starts_at' => GameClock::now()->addDays(2)->toIso8601ZuluString()]);
        $this->event(['kind' => 'progression', 'league_id' => $this->league['id'], 'starts_at' => $this->hours(1), 'ends_at' => $this->hours(3)])->assertCreated();
        $this->assertSame(10000, TimedEvents::times('progression', $this->league['id']));
        Carbon::setTestNow(GameClock::now()->addHours(2));
        $this->assertSame(20000, TimedEvents::times('progression', $this->league['id']));
        $this->assertSame(10000, TimedEvents::times('progression', $other['id']));
        $this->actingAs($this->owner)->getJson("/api/v1/leagues/{$this->league['id']}/training")->assertOk()->assertJsonPath('events.0.kind', 'progression');
        Carbon::setTestNow(GameClock::now()->addHours(2));
        $this->assertSame(10000, TimedEvents::times('progression', $this->league['id']));
    }

    public function test_extreme_progression_doubles_every_session(): void
    {
        $p = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('players.club_id', $this->mine)->whereColumn('master_players.potential', '>', 'players.overall')->orderBy('players.id')->first(['players.id']);
        Training::add($this->mine, $p->id);
        Carbon::setTestNow(GameClock::now()->addSeconds(Training::interval($this->league['id'])));
        Training::due();
        $one = (int) DB::table('players')->where('id', $p->id)->value('training_progress');
        // The same session again, in an extreme progression: twice the step.
        DB::table('players')->where('id', $p->id)->update(['training_progress' => 0]);
        DB::table('training_slots')->update(['sessions' => 0, 'next_at' => GameClock::now()]);
        DB::table('club_transactions')->where('type', 'training')->delete();
        DB::table('clubs')->where('id', $this->mine)->update(['balance' => DB::raw('balance + '.Training::cost($this->league['id']))]);
        $this->event(['kind' => 'progression', 'ends_at' => $this->hours(5)])->assertCreated();
        Training::due();
        $this->assertSame(2 * $one, (int) DB::table('players')->where('id', $p->id)->value('training_progress'));
    }

    public function test_age_is_the_strongest_factor_in_training(): void
    {
        $gain = Gain::fromConfig();
        $this->assertGreaterThan($gain->step(75, 'k', 90, 30), $gain->step(75, 'k', 90, 19));
        $this->assertEqualsWithDelta(intdiv($gain->step(75, 'k', 90) * $gain->ageBp(33), 10000), $gain->step(75, 'k', 90, 33), 1);
        $this->assertGreaterThan($gain->run(75, 90, 60, 'old', 0, 33), $gain->run(75, 90, 60, 'young', 0, 19));
    }

    public function test_a_transfer_madness_hurries_the_buyers_and_the_market(): void
    {
        // An outfield player (a keeper may be one the club cannot let go).
        $p = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.club_id', $this->mine)
            ->where('master_players.line', '!=', 'gk')->orderByDesc('players.value')->orderBy('players.id')->first(['players.*']);
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/transfers/listings", ['player_id' => $p->id, 'price' => (int) $p->value])->assertOk();
        $l = DB::table('transfer_listings')->first();
        $wait = (int) GameClock::now()->diffInSeconds(Carbon::parse($l->sells_at, 'UTC'));
        // Half the wait gone: no buyer yet; a madness (twice as fast) starts and he goes now.
        Carbon::setTestNow(GameClock::now()->addSeconds(intdiv($wait, 2) + 5));
        $this->assertSame(0, Buyer::due());
        $this->event(['kind' => 'madness', 'ends_at' => $this->hours(5)])->assertCreated();
        $this->assertSame(1, Buyer::due());
        $this->assertNull(DB::table('players')->where('id', $p->id)->value('club_id'));

        // The market renews twice as often.
        $league = DB::table('leagues')->where('id', $this->league['id'])->first();
        $this->assertEquals(Carbon::parse($league->pool_renewed_at, 'UTC')->addSeconds(intdiv((int) config('game.economy.pool_hours') * 3600, 2)), Pool::renewsAt($league));
    }

    public function test_the_market_discount_and_the_special_players(): void
    {
        $pool = fn () => DB::table('players')->where('league_id', $this->league['id'])->whereNull('club_id')->where('in_pool', true);
        $plain = $pool()->orderBy('id')->first();
        $this->event(['kind' => 'discount', 'ends_at' => $this->hours(5), 'power' => 2500])->assertCreated();
        $this->assertSame(intdiv((int) $plain->value * 7500, 10000), Market::price($plain, $this->mine));

        // Their start renews the market at once, with the special players.
        Carbon::setTestNow(GameClock::now()->addMinute());
        $this->event(['kind' => 'offers', 'ends_at' => $this->hours(5), 'power' => 3000, 'count' => 3])->assertCreated();
        $this->event(['kind' => 'in_form', 'ends_at' => $this->hours(5), 'power' => 3, 'count' => 2])->assertCreated();
        $this->event(['kind' => 'legends', 'ends_at' => $this->hours(5), 'power' => 15, 'count' => 2])->assertCreated();
        Carbon::setTestNow(GameClock::now()->addMinute());
        // The test data is small: the old pool's players come back to it, and two legends from abroad.
        DB::table('players')->where('league_id', $this->league['id'])->whereNull('club_id')->delete();
        $best = (int) DB::table('players')->where('league_id', $this->league['id'])->whereNotNull('club_id')->max(DB::raw('overall + training_bonus'));
        $abroad = DB::table('master_clubs')->insertGetId(['data_version' => '2026', 'name' => 'Legends FC', 'code' => 'LGD', 'league_name' => 'Legends League',
            'strength_cp' => 9000, 'color_primary' => '#000000', 'color_secondary' => '#FFFFFF']);
        foreach ([1, 2] as $i) {
            DB::table('master_players')->insert(['data_version' => '2026', 'external_id' => 980000 + $i, 'master_club_id' => $abroad, 'name' => "Legend {$i}",
                'position' => 'ST', 'line' => 'att', 'age' => 30, 'overall' => $best + 2 * $i, 'potential' => $best + 2 * $i, 'value' => 9_000_000,
                'pac' => 90, 'sho' => 90, 'pas' => 85, 'dri' => 90, 'def' => 40, 'phy' => 80]);
        }
        $this->assertSame(1, Pool::due());
        $this->assertSame(3, $pool()->where('pool_kind', 'offer')->count());
        $offer = $pool()->where('pool_kind', 'offer')->first();
        // An offer has its own price (no second discount).
        $this->assertSame(intdiv((int) $offer->value * 7000, 10000), Market::price($offer, $this->mine));
        $form = $pool()->where('pool_kind', 'in_form')->get();
        $this->assertCount(2, $form);
        $this->assertTrue($form->every(fn ($p) => (int) $p->training_bonus === min(3, 99 - (int) $p->overall)));
        $legends = $pool()->where('pool_kind', 'legend')->get();
        $this->assertCount(2, $legends);
        $this->assertTrue($legends->every(fn ($p) => $p->overall > $best && Market::price($p, $this->mine) === intdiv((int) $p->value * 15000, 10000)));
        // Not twice for the same start.
        $this->assertSame(0, Pool::due());

        // The market shows them first, with the running events.
        $list = $this->actingAs($this->owner)->getJson("/api/v1/leagues/{$this->league['id']}/market?source=list&line=".DB::table('master_players')->where('id', $offer->master_player_id)->value('line'))
            ->assertOk()->json();
        // One per kind: the one in effect (the market's discount and the three that bring players).
        $this->assertCount(4, $list['events']);
        $this->event(['kind' => 'offers', 'ends_at' => $this->hours(5), 'power' => 4000])->assertCreated();
        $this->assertSame(4000, collect($this->actingAs($this->owner)->getJson("/api/v1/leagues/{$this->league['id']}/market?source=list")->json('events'))->firstWhere('kind', 'offers')['power']);
        $this->assertNotNull($list['players'][0]['special']);

        // Bought: an ordinary player of his club.
        Market::buy($this->mine, $offer->id, 'k-offer');
        $this->assertNull(DB::table('players')->where('id', $offer->id)->value('pool_kind'));
    }
}
