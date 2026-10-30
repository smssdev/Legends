<?php

namespace Tests\Feature;

use App\League\Morale;
use App\League\Predictions;
use App\League\PressRoom;
use App\Models\User;
use App\Season\Career;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [UP12] The owner's spec (6): the press conference, the coaches' predictions and the newspaper. */
class PressTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private User $coach;

    private array $league;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template();
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner);
        $this->coach = $this->approvedCoach($this->owner, $this->league);
        $this->actingAs($this->coach)->postJson("/api/v1/leagues/{$this->league['id']}/clubs/{$this->botClub($this->league['id'])}/claim")->assertCreated();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function myFixture(): object
    {
        $mine = $this->league['my_club_id'];

        return DB::table('fixtures')->where('competition', 'league')->where('is_bye', false)
            ->where(fn ($q) => $q->where('home_id', $mine)->orWhere('away_id', $mine))->orderBy('scheduled_at')->first();
    }

    private function url(string $path): string
    {
        return "/api/v1/leagues/{$this->league['id']}{$path}";
    }

    public function test_the_conference_opens_half_an_hour_before_and_a_statement_lifts_the_morale_once(): void
    {
        $f = $this->myFixture();
        $press = $this->actingAs($this->owner)->getJson($this->url("/press/{$f->id}"))->assertOk()->json('press');
        $this->assertFalse($press['open']);
        $this->assertSame(100, array_sum($press['chances']));
        $this->assertCount(3, $press['statements']);
        $this->postJson($this->url("/press/{$f->id}"), ['kind' => 'rally'])->assertConflict();

        Carbon::setTestNow(Carbon::parse($f->scheduled_at, 'UTC')->subMinutes(20));
        $side = $f->home_id === $this->league['my_club_id'] ? 'home' : 'away';
        $before = Morale::forMatch($f, $side);
        $this->postJson($this->url("/press/{$f->id}"), ['kind' => 'rally'])->assertOk()->assertJsonPath("press.said.{$side}", 'rally');
        $this->assertSame($before + 1, Morale::forMatch($f, $side));
        $this->postJson($this->url("/press/{$f->id}"), ['kind' => 'calm'])->assertConflict();
        // Only the match's coaches speak.
        $other = DB::table('fixtures')->where('competition', 'league')->where('is_bye', false)->where('home_id', '!=', $this->league['my_club_id'])
            ->where('away_id', '!=', $this->league['my_club_id'])->first();
        $this->postJson($this->url("/press/{$other->id}"), ['kind' => 'calm'])->assertForbidden();

        // [X61 E9] The statement shows its stakes, and after the match the result judges it, once.
        $this->assertSame(['win' => 2, 'draw' => 0, 'loss' => -1], collect($press['statements'])->firstWhere('kind', 'rally')['stakes']);
        $club = $this->league['my_club_id'];
        $morale = (int) DB::table('clubs')->where('id', $club)->value('morale');
        $this->assertSame(-1, PressRoom::judge($f, $club, 0, 2));
        $this->assertSame(0, PressRoom::judge($f, $club, 0, 2));
        $this->assertSame($morale - 1, (int) DB::table('clubs')->where('id', $club)->value('morale'));
    }

    public function test_a_right_prediction_pays_the_club_and_counts_on_the_career(): void
    {
        $round = $this->actingAs($this->owner)->getJson($this->url('/predictions'))->assertOk()->json();
        $this->assertSame(1, $round['round']);
        $f = $round['matches'][0];
        $this->postJson($this->url('/predictions'), ['fixture_id' => $f['fixture_id'], 'pick' => 'home'])->assertOk();
        $this->actingAs($this->coach)->postJson($this->url('/predictions'), ['fixture_id' => $f['fixture_id'], 'pick' => 'away'])->assertOk()
            ->assertJsonPath('matches.0.split', ['home' => 1, 'draw' => 0, 'away' => 1])->assertJsonPath('predictors', 2);
        // [Sprint 21 E4.4] A coach's second pick in the round is still one predictor.
        $this->postJson($this->url('/predictions'), ['fixture_id' => $round['matches'][1]['fixture_id'], 'pick' => 'draw'])->assertOk()->assertJsonPath('predictors', 2);
        $fixture = DB::table('fixtures')->find($f['fixture_id']);
        $balance = (int) DB::table('clubs')->where('id', $this->league['my_club_id'])->value('balance');
        Predictions::settle($fixture, 2, 0);
        Predictions::settle($fixture, 2, 0);   // once
        $this->assertSame($balance + Predictions::reward($this->league['id']), (int) DB::table('clubs')->where('id', $this->league['my_club_id'])->value('balance'));
        $this->assertSame([true, false], DB::table('match_predictions')->where('fixture_id', $f['fixture_id'])->orderBy('id')->pluck('correct')->map(fn ($c) => (bool) $c)->all());
        $this->assertSame(1, Career::record($this->owner->id)['predicted']);
        // Locked: no more picks.
        DB::table('fixtures')->where('id', $f['fixture_id'])->update(['status' => 'locked']);
        $this->actingAs($this->owner)->postJson($this->url('/predictions'), ['fixture_id' => $f['fixture_id'], 'pick' => 'draw'])->assertConflict();
    }

    public function test_the_newspaper_tells_the_round_and_the_owner_publishes_the_coaches_articles(): void
    {
        $this->actingAs($this->coach)->getJson($this->url('/newspaper'))->assertOk()->assertJsonPath('edition', null);
        $season = DB::table('seasons')->where('league_id', $this->league['id'])->value('id');
        $goals = [[5, 0], [3, 3], [1, 0]];
        foreach (DB::table('fixtures')->where('season_id', $season)->where('competition', 'league')->where('round', 1)->where('is_bye', false)->orderBy('id')->get() as $i => $f) {
            [$h, $a] = $goals[$i % 3];
            DB::table('fixtures')->where('id', $f->id)->update(['status' => 'finished', 'home_goals' => $h, 'away_goals' => $a]);
        }
        $paper = $this->getJson($this->url('/newspaper'))->assertOk()->json();
        $this->assertSame(1, $paper['edition']['round']);
        $this->assertContains('big_win', array_column($paper['edition']['stories'], 'kind'));
        $this->assertContains('goals', array_column($paper['edition']['stories'], 'kind'));

        // A coach writes; it waits for the owner, who publishes it.
        $this->postJson($this->url('/newspaper/articles'), ['title' => 'رسالة للمنافسين', 'body' => 'سنكون أبطال هذا الموسم، انتظروا.'])->assertOk()
            ->assertJsonCount(0, 'articles')->assertJsonCount(1, 'pending');
        $id = (int) DB::table('league_articles')->value('id');
        $this->postJson($this->url("/newspaper/articles/{$id}/decide"), ['publish' => true])->assertForbidden();
        $this->actingAs($this->owner)->getJson($this->url('/newspaper'))->assertJsonPath('is_owner', true)->assertJsonCount(1, 'pending');
        $this->postJson($this->url("/newspaper/articles/{$id}/decide"), ['publish' => true])->assertOk()->assertJsonPath('articles.0.title', 'رسالة للمنافسين');
        $this->postJson($this->url("/newspaper/articles/{$id}/decide"), ['publish' => false])->assertConflict();
    }

    public function test_one_article_a_round_and_the_league_news_tells_its_best_matches_player_coach_and_scandals(): void
    {
        $season = DB::table('seasons')->where('league_id', $this->league['id'])->value('id');
        // [Sprint 21 E4.5] One article a round, published or not.
        $this->actingAs($this->coach)->postJson($this->url('/newspaper/articles'), ['title' => 'المقال الأول', 'body' => 'هذا مقال الجولة الأولى كاملاً.'])->assertOk()
            ->assertJsonPath('wrote_this_round', true)->assertJsonPath('round', 1);
        $this->postJson($this->url('/newspaper/articles'), ['title' => 'المقال الثاني', 'body' => 'مقال ثانٍ في الجولة نفسها.'])->assertConflict()
            ->assertJsonPath('message', 'لك مقال واحد في كل جولة، وكتبت مقال الجولة 1.');
        $this->actingAs($this->owner)->getJson($this->url('/newspaper'))->assertJsonPath('wrote_this_round', false);

        // Round 1 played: the coach's side wins away against a stronger one, and an exposed bribe.
        $mine = (int) DB::table('clubs')->where('league_id', $this->league['id'])->where('user_id', $this->coach->id)->value('id');
        $fixtures = DB::table('fixtures')->where('season_id', $season)->where('competition', 'league')->where('round', 1)->where('is_bye', false)->orderBy('id')->get();
        foreach ($fixtures as $f) {
            $won = $f->away_id === $mine || $f->home_id === $mine;
            DB::table('fixtures')->where('id', $f->id)->update(['status' => 'finished', 'home_goals' => $won && $f->away_id === $mine ? 0 : 2, 'away_goals' => $won && $f->away_id === $mine ? 3 : ($won ? 0 : 2)]);
        }
        $bribe = DB::table('bribes')->insertGetId(['fixture_id' => $fixtures[0]->id, 'club_id' => $fixtures[0]->home_id, 'money' => 1, 'outcome' => 'clean', 'created_at' => GameClock::now()]);
        DB::table('fa_cases')->insert(['season_id' => $season, 'bribe_id' => $bribe, 'accuser_club_id' => $fixtures[0]->away_id, 'accused_club_id' => $fixtures[0]->home_id, 'fine' => 1000, 'points' => 3, 'created_at' => GameClock::now()]);
        // Round 2 is open now: a new article is allowed.
        $this->actingAs($this->coach)->postJson($this->url('/newspaper/articles'), ['title' => 'مقال الجولة الثانية', 'body' => 'وهذا مقال الجولة الثانية.'])->assertOk()->assertJsonPath('round', 2);

        $news = $this->getJson($this->url('/newspaper'))->json('edition');
        $this->assertCount(min(3, $fixtures->count()), $news['best_matches']);
        $this->assertGreaterThanOrEqual($news['best_matches'][1]['score'] ?? 0, $news['best_matches'][0]['score']);
        $this->assertSame($this->coach->id, $news['coach']['coach']['id']);
        $this->assertSame(1, count($news['scandals']));
        $this->assertSame(3, $news['scandals'][0]['points']);
        $this->assertArrayHasKey('player', $news);
    }
}
