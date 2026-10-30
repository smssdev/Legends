<?php

namespace Tests\Feature;

use App\League\Friendlies;
use App\Models\User;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/**
 * [Sprint 27 B1, B2, B3, the owner's request 2026-10-30] The league's days off, a match moved by whole hours on its own
 * day when the other coach agrees, and the friendly's quick simulation.
 */
class RestDaysAndMovesTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    protected function setUp(): void
    {
        parent::setUp();
        // A Thursday.
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function cairo(string $utc): Carbon
    {
        return Carbon::parse($utc, 'UTC')->timezone('Africa/Cairo');
    }

    public function test_no_match_is_played_on_the_league_s_days_off(): void
    {
        $league = $this->makeLeague($this->owner, ['team_count' => 6, 'rest_days' => [5, 6]]);
        $this->assertSame([5, 6], $league['rest_days']);
        $season = DB::table('seasons')->where('league_id', $league['id'])->first();
        $days = DB::table('fixtures')->where('season_id', $season->id)->pluck('scheduled_at')->map(fn ($t) => $this->cairo($t)->dayOfWeekIso)->unique()->values()->all();
        $this->assertNotEmpty($days);
        $this->assertEmpty(array_intersect($days, [5, 6]), 'no match on Friday or Saturday');
        // Still every round, one a day on the other days.
        $this->assertSame(10, DB::table('fixtures')->where('season_id', $season->id)->where('competition', 'league')->distinct()->count('round'));

        // The owner changes them before the start: the calendar is made again (Friday only now).
        $this->patchJson("/api/v1/leagues/{$league['id']}", ['rest_days' => [5]])->assertOk()->assertJsonPath('league.rest_days', [5]);
        $days = DB::table('fixtures')->where('season_id', $season->id)->pluck('scheduled_at')->map(fn ($t) => $this->cairo($t)->dayOfWeekIso)->unique()->all();
        $this->assertNotContains(5, $days);
        $this->assertContains(6, $days);
        // Three days off a week at most; ISO weekdays only. And free: it never makes a league customized.
        $this->patchJson("/api/v1/leagues/{$league['id']}", ['rest_days' => [1, 2, 3, 4]])->assertUnprocessable()->assertJsonValidationErrors('rest_days');
        $this->patchJson("/api/v1/leagues/{$league['id']}", ['rest_days' => [8]])->assertUnprocessable()->assertJsonValidationErrors('rest_days.0');
    }

    /** A league whose first match is a coach against a coach, the next day at 21:00 Cairo. */
    private function twoCoaches(): array
    {
        $league = $this->makeLeague($this->owner, ['team_count' => 6, 'starts_at' => '2026-10-22T10:30:00Z']);
        $coach = $this->approvedCoach($this->owner, $league);
        $mine = $league['my_club_id'];
        $f = DB::table('fixtures')->where('competition', 'league')->where('round', 1)->where('is_bye', false)
            ->where(fn ($q) => $q->where('home_id', $mine)->orWhere('away_id', $mine))->first();
        $theirs = $f->home_id === $mine ? $f->away_id : $f->home_id;
        DB::table('clubs')->where('id', $theirs)->update(['user_id' => $coach->id]);

        return [$league, $coach, $f];
    }

    public function test_a_match_moves_by_hours_on_its_day_when_the_other_coach_accepts(): void
    {
        [$league, $coach, $f] = $this->twoCoaches();
        $base = "/api/v1/leagues/{$league['id']}/team";
        $at = Carbon::parse($f->scheduled_at, 'UTC');
        $this->assertSame('21:00', $this->cairo($f->scheduled_at)->format('H:i'));

        $view = $this->actingAs($this->owner)->getJson("{$base}/next-match")->assertOk()->json('match.move');
        $this->assertNull($view['pending']);
        $this->assertSame(2, $view['moves_left']);
        // The same day only: from 21:00 Cairo, up to two hours later (23:00) and back to the small hours.
        $this->assertContains(-3, $view['hours']);
        $this->assertContains(2, $view['hours']);
        $this->assertNotContains(3, $view['hours']);
        $this->assertNotContains(0, $view['hours']);

        $this->postJson("{$base}/moves", ['fixture_id' => $f->id, 'hours' => 3])->assertStatus(422);
        $move = $this->postJson("{$base}/moves", ['fixture_id' => $f->id, 'hours' => -3])->assertCreated()->assertJsonPath('move.status', 'pending')->json('move');
        // One waiting at a time, and the time has not moved yet.
        $this->postJson("{$base}/moves", ['fixture_id' => $f->id, 'hours' => -2])->assertStatus(409);
        $this->assertEquals($at, Carbon::parse(DB::table('fixtures')->find($f->id)->scheduled_at, 'UTC'));
        // The other coach is told, and only he answers.
        $this->assertSame(1, DB::table('messages')->where('user_id', $coach->id)->where('type', 'match_move')->count());
        $this->postJson("{$base}/moves/{$move['id']}/accept")->assertForbidden();

        $this->actingAs($coach)->getJson("{$base}/next-match")->assertOk()->assertJsonPath('match.move.pending.mine', false);
        $this->postJson("{$base}/moves/{$move['id']}/accept")->assertOk()->assertJsonPath('move.status', 'accepted');
        $moved = DB::table('fixtures')->find($f->id);
        $this->assertSame('18:00', $this->cairo($moved->scheduled_at)->format('H:i'));
        $this->assertNull($moved->lock_at);
        $this->assertSame(1, DB::table('messages')->where('user_id', $this->owner->id)->where('type', 'match_move')->count());
        $this->postJson("{$base}/moves/{$move['id']}/accept")->assertStatus(409);

        // Declined: it stays.
        $again = $this->actingAs($this->owner)->postJson("{$base}/moves", ['fixture_id' => $f->id, 'hours' => 1])->assertCreated()->json('move');
        $this->actingAs($coach)->postJson("{$base}/moves/{$again['id']}/decline")->assertOk()->assertJsonPath('move.status', 'declined');
        $this->assertSame('18:00', $this->cairo(DB::table('fixtures')->find($f->id)->scheduled_at)->format('H:i'));
        // Cancelled by the one who asked (the other coach this time).
        $third = $this->postJson("{$base}/moves", ['fixture_id' => $f->id, 'hours' => 2])->assertCreated()->json('move');
        $this->deleteJson("{$base}/moves/{$third['id']}")->assertNoContent();
        $this->assertSame('cancelled', DB::table('fixture_moves')->find($third['id'])->status);
    }

    public function test_too_late_to_move_and_a_request_lapses(): void
    {
        [$league, $coach, $f] = $this->twoCoaches();
        $base = "/api/v1/leagues/{$league['id']}/team";
        $move = $this->actingAs($this->owner)->postJson("{$base}/moves", ['fixture_id' => $f->id, 'hours' => 1])->assertCreated()->json('move');
        // Within the hour before the match: the request has lapsed and nothing more may be asked.
        Carbon::setTestNow(Carbon::parse($f->scheduled_at, 'UTC')->subMinutes(50));
        $this->actingAs($coach)->postJson("{$base}/moves/{$move['id']}/accept")->assertStatus(409);
        $this->assertSame('expired', DB::table('fixture_moves')->find($move['id'])->status);
        $this->getJson("{$base}/next-match")->assertOk()->assertJsonPath('match.move.hours', []);
        $this->postJson("{$base}/moves", ['fixture_id' => $f->id, 'hours' => 1])->assertStatus(422);
    }

    public function test_a_bot_club_agrees_at_once(): void
    {
        $league = $this->makeLeague($this->owner, ['team_count' => 6, 'starts_at' => '2026-10-22T10:30:00Z']);
        $mine = $league['my_club_id'];
        $f = DB::table('fixtures')->where('competition', 'league')->where('round', 1)->where('is_bye', false)
            ->where(fn ($q) => $q->where('home_id', $mine)->orWhere('away_id', $mine))->first();
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$league['id']}/team/moves", ['fixture_id' => $f->id, 'hours' => -1])
            ->assertCreated()->assertJsonPath('move.status', 'accepted');
        $this->assertSame('20:00', $this->cairo(DB::table('fixtures')->find($f->id)->scheduled_at)->format('H:i'));
        // Another club's match is not mine to move.
        $other = DB::table('fixtures')->where('competition', 'league')->where('round', 1)->where('is_bye', false)
            ->where('home_id', '!=', $mine)->where('away_id', '!=', $mine)->first();
        $this->postJson("/api/v1/leagues/{$league['id']}/team/moves", ['fixture_id' => $other->id, 'hours' => -1])->assertNotFound();
    }

    public function test_the_friendly_carries_a_minute_by_minute_quick_simulation(): void
    {
        $league = $this->makeLeague($this->owner, ['team_count' => 4, 'starts_at' => '2026-10-24T10:00:00Z', 'fair_league' => false]);
        Wallet::post($this->owner->id, 'admin_gift', 10, 'gift:t');
        $opponent = DB::table('clubs')->where('league_id', $league['id'])->where('id', '!=', $league['my_club_id'])->value('id');
        $f = $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$league['id']}/friendlies", ['opponent_id' => $opponent, 'idempotency_key' => (string) Str::uuid()])
            ->assertCreated()->json('friendly');
        $timeline = $f['report']['timeline'];
        $this->assertGreaterThanOrEqual(90, count($timeline));
        // The minutes in order, the score never going back, and the last one the result.
        $this->assertSame(array_column($timeline, 'm'), collect($timeline)->pluck('m')->sort()->values()->all());
        $this->assertSame([$f['goals_for'], $f['goals_against']], end($timeline)['score']);
        $goals = array_values(array_filter($timeline, fn ($m) => $m['k'] === 'goal'));
        $this->assertCount($f['goals_for'] + $f['goals_against'], $goals);
        foreach ($goals as $g) {
            $this->assertNotNull($g['name']);
        }
        $this->assertArrayHasKey('shots', $f['report']['stats']['home']);

        // The moment of a minute is pure: the biggest thing in it.
        $this->assertSame(['m' => 7, 'k' => 'quiet', 'score' => [0, 0]], Friendlies::moment(7, [], ['home' => 0, 'away' => 0]));
        $m = Friendlies::moment(12, [['type' => 'attack', 'team' => 'away', 'result' => 'saved', 'shooter' => 5], ['type' => 'card', 'team' => 'home', 'player' => 3, 'color' => 'yellow']], ['home' => 0, 'away' => 0]);
        $this->assertSame(['m' => 12, 'k' => 'saved', 's' => 'away', 'p' => 5, 'score' => [0, 0]], $m);
    }
}
