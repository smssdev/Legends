<?php

namespace Tests\Feature;

use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 20 B1 to B3] The club board in one request, the home slots' counts, and the matches a coach missed. */
class ClubBoardTest extends TestCase
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
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1, 'starts_at' => '2026-10-22T10:00:00Z']);
        $this->mine = $this->league['my_club_id'];
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/start")->assertOk();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function url(string $path): string
    {
        return "/api/v1/leagues/{$this->league['id']}/team/{$path}";
    }

    public function test_the_board_says_everything_in_one_request_and_nothing_of_the_opponents_tactics(): void
    {
        $board = $this->getJson($this->url('summary'))->assertOk()
            // [Sprint 59 F1] The fields the app reads through ClubBoard (openapi.yaml).
            ->assertJsonStructure(['club' => ['id', 'name', 'code', 'crest_url'], 'money' => ['cash', 'coins'], 'lineup' => ['auto', 'ready', 'formation'],
                'standings' => ['position', 'teams', 'top'], 'board', 'missed', 'pending', 'timers', 'match'])->json();
        $this->assertSame($this->mine, $board['club']['id']);
        $this->assertNotNull($board['match']);
        $this->assertSame('scheduled', $board['match']['status']);
        // Before the lock: no formation and no tactics of his, ever any private one.
        $this->assertNull($board['match']['opponent']['formation']);
        $this->assertNull($board['match']['opponent']['tactics']);
        $this->assertSame(4, $board['standings']['teams']);
        $this->assertTrue($board['lineup']['ready']);
        $this->assertSame('calm', $board['board']['mood']);
        $kinds = array_column($board['timers'], 'kind');
        $this->assertContains('match', $kinds);
        $this->assertSame('daily', $board['timers'][0]['kind']);   // ready now: first
        $this->assertNull($board['timers'][0]['at']);
        foreach (['pressing', 'style', 'tempo', 'att', 'mid', 'def'] as $private) {
            $this->assertStringNotContainsString("\"{$private}\"", json_encode($board['match']['opponent']));
        }

        // An injured starter is the first thing waiting, and the lineup is not ready; the home slot counts it.
        // (A saved lineup: the automatic one already leaves the injured out.)
        $best = $this->getJson($this->url('suggestion'))->assertOk()->json('lineup');
        $this->putJson($this->url('lineup'), ['formation' => $best['formation'], 'starters' => $best['starters'], 'bench' => $best['bench']])->assertOk();
        DB::table('players')->where('id', $best['starters'][0])->update(['injured_matches' => 2]);
        $board = $this->getJson($this->url('summary'))->json();
        $this->assertSame('lineup', $board['pending'][0]['kind']);
        $this->assertSame('injured', $board['pending'][0]['players'][0]['why']);
        $this->assertFalse($board['lineup']['ready']);
        $slot = collect($this->getJson('/api/v1/home')->assertOk()->json('slots'))->firstWhere('state', 'club');
        $this->assertSame(count($board['pending']), $slot['pending']);

        // Someone else's club: no board.
        $this->actingAs(User::factory()->create())->getJson($this->url('summary'))->assertForbidden();
    }

    public function test_a_missed_match_waits_in_the_after_round_window_until_seen(): void
    {
        $f = DB::table('fixtures')->where('season_id', DB::table('seasons')->where('league_id', $this->league['id'])->value('id'))
            ->where(fn ($q) => $q->where('home_id', $this->mine)->orWhere('away_id', $this->mine))->whereNotNull('home_id')->whereNotNull('away_id')->orderBy('scheduled_at')->first();
        $home = $f->home_id === $this->mine;
        DB::table('fixtures')->where('id', $f->id)->update(['status' => 'finished', 'home_goals' => $home ? 2 : 0, 'away_goals' => $home ? 0 : 2, 'scheduled_at' => GameClock::now()->subHour()]);
        $now = GameClock::now();
        $match = DB::table('matches')->insertGetId(['fixture_id' => $f->id, 'seed' => 1, 'engine_version' => 1, 'config_snapshot' => '{}', 'initial_state' => '{}', 'state' => '{}',
            'home_goals' => $home ? 2 : 0, 'away_goals' => $home ? 0 : 2, 'mode' => 'league', 'status' => 'finished', 'started_at' => $now, 'finished_at' => $now, 'created_at' => $now, 'updated_at' => $now]);
        $scorer = DB::table('players')->where('club_id', $this->mine)->value('id');
        foreach ([12, 77] as $minute) {
            DB::table('match_events')->insert(['match_id' => $match, 'tick' => $minute, 'minute' => $minute, 'type' => 'goal', 'club_id' => $this->mine, 'player_id' => $scorer, 'payload' => '{}']);
        }

        $missed = $this->getJson($this->url('missed'))->assertOk()->assertJsonCount(1, 'matches')->json('matches.0');
        $this->assertSame($match, $missed['match_id']);
        $this->assertSame(1, $missed['result']);
        // [Sprint 26 B2] A 2-0 win: the mascot is happy.
        $this->assertSame('joy', $missed['mood']);
        $this->assertCount(2, $missed['goals']);
        $this->assertSame($home ? 'home' : 'away', $missed['goals'][0]['side']);
        $this->assertSame(1, $this->getJson($this->url('summary'))->json('missed'));

        // "Skip" marks it seen; it does not come back.
        $this->postJson($this->url('missed/seen'))->assertOk()->assertJsonCount(0, 'matches');
        $this->getJson($this->url('missed'))->assertJsonCount(0, 'matches');
        $this->assertSame(0, $this->getJson($this->url('summary'))->json('missed'));
    }

    /** [Sprint 24 B1] The quick recap of a missed match: once it is over, it counts as seen. [X69] For every member of the league. */
    public function test_the_quick_recap_of_a_missed_match(): void
    {
        $f = DB::table('fixtures')->where('season_id', DB::table('seasons')->where('league_id', $this->league['id'])->value('id'))
            ->where(fn ($q) => $q->where('home_id', $this->mine)->orWhere('away_id', $this->mine))->whereNotNull('home_id')->whereNotNull('away_id')->orderBy('scheduled_at')->first();
        $side = $f->home_id === $this->mine ? 'home' : 'away';
        DB::table('fixtures')->where('id', $f->id)->update(['status' => 'finished', 'home_goals' => 1, 'away_goals' => 0, 'scheduled_at' => GameClock::now()->subHour()]);
        $now = GameClock::now();
        $match = DB::table('matches')->insertGetId(['fixture_id' => $f->id, 'seed' => 1, 'engine_version' => 1, 'config_snapshot' => '{}', 'initial_state' => '{}', 'state' => '{}',
            'home_goals' => 1, 'away_goals' => 0, 'mode' => 'league', 'status' => 'live', 'started_at' => $now, 'created_at' => $now, 'updated_at' => $now]);
        $player = (int) DB::table('players')->where('club_id', $f->home_id)->value('id');
        $report = ['result' => $side === 'home' ? 'win' : 'loss', 'score' => ['home' => 1, 'away' => 0], 'shootout' => null,
            'timeline' => [['minute' => 33, 'type' => 'goal', 'team' => 'home', 'scorer' => $player, 'assist' => 0, 'score' => ['home' => 1, 'away' => 0]]],
            'ratings' => ['home' => [['id' => $player, 'name' => 'Scorer', 'rating' => 800]], 'away' => []],
            'stats' => ['home' => ['attacks' => 30, 'shots' => 9], 'away' => ['attacks' => 20, 'shots' => 4]], 'man_of_the_match' => null];
        DB::table('match_reports')->insert(['match_id' => $match, 'club_id' => $this->mine, 'report' => json_encode($report), 'created_at' => $now]);

        // Not before the end.
        $this->getJson("/api/v1/matches/{$match}/recap")->assertConflict();
        DB::table('matches')->where('id', $match)->update(['status' => 'finished', 'finished_at' => $now]);
        $this->getJson($this->url('missed'))->assertJsonCount(1, 'matches');

        $recap = $this->getJson("/api/v1/matches/{$match}/recap")->assertOk()
            ->assertJsonPath('side', $side)->assertJsonPath('score.home', 1)->assertJsonPath('home.id', $f->home_id)
            ->assertJsonPath('moments.0.player', 'Scorer')->assertJsonPath('moments.0.score.home', 1)
            ->assertJsonPath('stats.home.possession', 60)->assertJsonPath('stats.away.shots', 4)->json();
        $this->assertSame(['Scorer'], array_column($recap['best']['home'], 'name'));
        // Seen: the after-round window no longer offers it.
        $this->getJson($this->url('missed'))->assertJsonCount(0, 'matches');
        // [X69] A member who coaches neither side sees it too, with no side and the home side's result; an outsider never does.
        $member = $this->memberOutside($this->league, [$f->home_id, $f->away_id]);
        $this->actingAs($member)->getJson("/api/v1/matches/{$match}/recap")->assertOk()
            ->assertJsonPath('side', null)->assertJsonPath('result', 'win')->assertJsonPath('moments.0.player', 'Scorer');
        $this->actingAs(User::factory()->create())->getJson("/api/v1/matches/{$match}/recap")->assertNotFound();
    }
}
