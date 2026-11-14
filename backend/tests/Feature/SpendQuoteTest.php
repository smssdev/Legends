<?php

namespace Tests\Feature;

use App\Market\Scout;
use App\Models\User;
use App\Stadium\Stadium;
use App\Support\GameClock;
use App\Training\Training;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 64 B4] Every spend says before it is made what is left after it, and when what it buys ends. */
class SpendQuoteTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    public function test_training_stadium_scout_and_specialists_say_what_is_left_and_when_it_ends(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 4, 'starts_at' => GameClock::now()->addDays(2)->toIso8601ZuluString()]);
        $id = $league['id'];
        $balance = (int) DB::table('clubs')->where('id', $league['my_club_id'])->value('balance');
        $at = fn (int $seconds) => GameClock::now()->addSeconds($seconds)->toIso8601ZuluString();
        $as = $this->actingAs($owner);

        $q = $as->getJson("/api/v1/leagues/{$id}/training")->assertOk()->json('quote');
        $cost = Training::cost($id);
        $this->assertSame(['currency' => 'money', 'amount' => $cost, 'have' => $balance, 'after' => $balance - $cost,
            'can' => $balance >= $cost, 'ends_at' => $at(Training::interval($id))], $q);

        $q = $as->getJson("/api/v1/leagues/{$id}/stadium")->assertOk()->json('sections.0.next.quote');
        $this->assertSame($balance - $q['amount'], $q['after']);
        $this->assertSame($at(Stadium::partSeconds($id)), $q['ends_at']);

        $q = $as->getJson("/api/v1/leagues/{$id}/scout")->assertOk()->json('quote');
        $this->assertSame($balance - Scout::cost($id), $q['after']);

        $offer = $as->getJson("/api/v1/leagues/{$id}/specialists")->assertOk()->json('specialists.0.offers.2');
        $this->assertSame($offer['cost'], $offer['quote']['amount']);
        $this->assertSame($offer['currency'], $offer['quote']['currency']);
        $this->assertSame($offer['quote']['have'] - $offer['cost'], $offer['quote']['after']);
        $this->assertNotNull($offer['quote']['ends_at']);
        Carbon::setTestNow();
    }
}
