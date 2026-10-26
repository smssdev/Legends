<?php

namespace Tests\Feature;

use App\Engine\MatchSetup;
use App\League\Tactics;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** Tactics, the referee and the lock [Sprint 17, PLAN 2.13, 2.14]. */
class MatchPrepTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private User $rival;

    private array $league;

    private object $fixture;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'rounds_per_day' => 1, 'round_times' => ['21:00']]);
        $mine = $this->league['my_club_id'];
        $this->fixture = DB::table('fixtures')->where('competition', 'league')->where('round', 1)
            ->where(fn ($q) => $q->where('home_id', $mine)->orWhere('away_id', $mine))->first();
        // The first opponent has a coach too.
        $this->rival = $this->approvedCoach($this->owner, $this->league);
        $theirs = $this->fixture->home_id === $mine ? $this->fixture->away_id : $this->fixture->home_id;
        $this->actingAs($this->rival)->postJson("/api/v1/leagues/{$this->league['id']}/clubs/{$theirs}/claim")->assertCreated();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function at(int $minutesBefore): void
    {
        Carbon::setTestNow(Carbon::parse($this->fixture->scheduled_at, 'UTC')->subMinutes($minutesBefore));
        $this->artisan('matches:prepare')->assertSuccessful();
    }

    private function url(string $path = ''): string
    {
        return "/api/v1/leagues/{$this->league['id']}/team{$path}";
    }

    public function test_tactics_are_saved_checked_and_explained(): void
    {
        $this->actingAs($this->owner);
        $this->getJson($this->url('/tactics'))->assertOk()->assertJsonPath('tactics.pressing', 50)->assertJsonPath('tactics.plan', 'passing');
        // A "?" for every part [X5].
        $help = $this->getJson($this->url('/tactics'))->json('help');
        $this->assertSame(['plan', 'pressing', 'style', 'tempo', 'tackling', 'lines', 'trap', 'marking', 'tips'], array_keys($help));
        $res = $this->putJson($this->url('/tactics'), ['pressing' => 85, 'tackling' => 3, 'plan' => 'counter', 'trap' => 1])->assertOk();
        $this->assertSame([85, 3, 'counter', 1], [$res->json('tactics.pressing'), $res->json('tactics.tackling'), $res->json('tactics.plan'), $res->json('tactics.trap')]);
        $tips = implode(' ', $res->json('tips'));
        $this->assertStringContainsString('ضغط عالٍ مع قطع قوي', $tips);
        $this->assertStringContainsString('المرتد', $tips);
        $this->assertStringContainsString('مصيدة التسلل', $tips);
        $this->putJson($this->url('/tactics'), ['pressing' => 101])->assertJsonValidationErrors('pressing');
        $this->putJson($this->url('/tactics'), ['plan' => 'tiki-taka'])->assertJsonValidationErrors('plan');
        // A strict referee changes the tip, not a number.
        $this->assertStringContainsString('الحكم صارم', implode(' ', Tactics::tips(['tackling' => 3, 'pressing' => 85] + MatchSetup::DEFAULT_TACTICS, 'strict')));
    }

    public function test_the_referee_is_drawn_30_minutes_before(): void
    {
        $this->at(31);
        $this->assertNull(DB::table('fixtures')->where('id', $this->fixture->id)->value('referee_strictness'));
        $this->at(30);
        $this->assertContains(DB::table('fixtures')->where('id', $this->fixture->id)->value('referee_strictness'), Tactics::REFEREES);
        $this->actingAs($this->owner)->getJson($this->url('/next-match'))->assertOk()->assertJsonPath('match.fixture_id', $this->fixture->id)
            ->assertJsonPath('match.status', 'scheduled')->assertJsonPath('match.opponent.sheet', null);
    }

    public function test_the_lock_replaces_the_injured_and_freezes_the_sheet(): void
    {
        $this->actingAs($this->owner);
        $team = $this->getJson($this->url())->json();
        $starters = $team['lineup']['starters'];
        $this->putJson($this->url('/lineup'), ['formation' => $team['lineup']['formation'], 'starters' => $starters, 'bench' => $team['lineup']['bench']])->assertOk();
        $injured = $starters[4];
        DB::table('players')->where('id', $injured)->update(['injured_matches' => 3]);

        $this->at(6);
        $this->assertSame('scheduled', DB::table('fixtures')->where('id', $this->fixture->id)->value('status'));
        $this->at(5);
        $this->assertSame('locked', DB::table('fixtures')->where('id', $this->fixture->id)->value('status'));

        $sheet = DB::table('fixture_sheets')->where('fixture_id', $this->fixture->id)->where('club_id', $this->league['my_club_id'])->first();
        $frozen = json_decode($sheet->starters);
        $this->assertNotContains($injured, $frozen);
        $this->assertCount(11, array_filter($frozen));
        $fix = json_decode($sheet->fixes, true);
        $this->assertSame([4, $injured], [$fix[0]['slot'], $fix[0]['out']]);
        $this->assertSame($frozen[4], $fix[0]['in']);
        $next = $this->getJson($this->url('/next-match'))->json('match');
        $this->assertSame('locked', $next['status']);
        $this->assertSame($fix[0]['in'], $next['mine']['fixes'][0]['in']);

        // Frozen until the match ends.
        $msg = 'التشكيلة والتكتيك مقفلان قبل المباراة بخمس دقائق وحتى نهايتها.';
        $this->putJson($this->url('/lineup'), ['formation' => $team['lineup']['formation'], 'starters' => $starters, 'bench' => $team['lineup']['bench']])->assertConflict()->assertJsonPath('message', $msg);
        $this->putJson($this->url('/tactics'), ['pressing' => 10])->assertConflict()->assertJsonPath('message', $msg);
        $this->putJson($this->url('/takers'), [])->assertConflict();
        $this->deleteJson($this->url('/lineup'))->assertConflict();
        // Running again changes nothing.
        $this->at(4);
        $this->assertSame(2, DB::table('fixture_sheets')->where('fixture_id', $this->fixture->id)->count());
        // Once the match is over, the coach edits again.
        DB::table('fixtures')->where('id', $this->fixture->id)->update(['status' => 'finished']);
        $this->putJson($this->url('/tactics'), ['pressing' => 10])->assertOk();
    }

    public function test_the_hidden_tactics_never_reach_the_opponent(): void
    {
        $secret = ['pressing' => 93, 'style' => 87, 'tempo' => 91, 'att' => 'only', 'mid' => 'push', 'def' => 'fullbacks', 'tackling' => 2, 'marking' => 'man', 'plan' => 'wings', 'trap' => 1];
        $this->actingAs($this->rival)->putJson($this->url('/tactics'), $secret)->assertOk();
        $this->at(5);

        $this->actingAs($this->owner);
        $seen = $this->getJson($this->url('/next-match'))->assertOk()->json('match.opponent.sheet');
        $this->assertSame(['tackling' => 2, 'marking' => 'man', 'plan' => 'wings', 'trap' => 1], $seen['tactics']);
        $this->assertCount(11, $seen['starters']);
        // Not in any answer the owner can get: no key, and not the values either.
        $id = $this->league['id'];
        $theirs = DB::table('clubs')->where('user_id', $this->rival->id)->value('id');
        foreach (["/api/v1/leagues/{$id}", "/api/v1/leagues/{$id}/clubs", "/api/v1/leagues/{$id}/clubs/{$theirs}", "/api/v1/leagues/{$id}/fixtures",
            "/api/v1/leagues/{$id}/standings", "/api/v1/leagues/{$id}/cup", $this->url('/next-match'), '/api/v1/leagues'] as $url) {
            $res = $this->getJson($url)->assertOk();
            // In the next match, "mine" is the owner's own tactics: what matters is the opponent part.
            $body = $url === $this->url('/next-match') ? json_encode($res->json('match.opponent')) : $res->getContent();
            // Without the ids, which may happen to be one of the hidden numbers (PostgreSQL's ids keep counting).
            $body = preg_replace('/"(\w+_)?id":\d+/', '', $body);
            foreach (['pressing', 'style', 'tempo', 'positioning', 'shape', '"att":', '"mid":', '"def":"', 'fullbacks', '"only"', '"push"', ':93', ':87', ':91'] as $hidden) {
                $this->assertStringNotContainsString($hidden, $body, "{$url} shows {$hidden}");
            }
        }
        // The rival's own view has everything.
        $this->actingAs($this->rival)->getJson($this->url('/tactics'))->assertJsonPath('tactics.tempo', 91);
        $this->assertSame(91, $this->getJson($this->url('/next-match'))->json('match.mine.tactics.tempo'));
    }

    public function test_a_bot_side_is_locked_with_the_automatic_sheet_and_its_personalitys_tactics(): void
    {
        $bot = DB::table('fixtures')->where('competition', 'league')->where('round', 1)->whereNotIn('id', [$this->fixture->id])->where('is_bye', false)->first();
        Carbon::setTestNow(Carbon::parse($bot->scheduled_at, 'UTC')->subMinutes(5));
        $this->artisan('matches:prepare')->assertSuccessful();
        $sheets = DB::table('fixture_sheets')->where('fixture_id', $bot->id)->get();
        $this->assertCount(2, $sheets);
        foreach ($sheets as $s) {
            // Its personality's tactics, with every knob a valid one [Sprint 32].
            $t = json_decode($s->tactics, true);
            $this->assertSame(array_keys(MatchSetup::DEFAULT_TACTICS), array_keys($t));
            $persona = config('game.bots.personalities.'.DB::table('clubs')->where('id', $s->club_id)->value('bot_personality'));
            $this->assertSame($persona['pressing'], $t['pressing']);
            $this->assertCount(11, array_filter(json_decode($s->starters)));
        }
        $this->assertTrue(GameClock::now()->gte(Carbon::parse($bot->scheduled_at)->subMinutes(5)));
    }
}
