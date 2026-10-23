<?php

namespace Tests\Feature;

use App\League\Bot;
use App\League\Leaving;
use App\League\MatchRunner;
use App\Models\Club;
use App\Models\LeagueMembership;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** The bots between matches [ENGINE 7, Sprint 32]: a season with no human, and nothing hidden read. */
class BotsTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        // A development league: a round every minute.
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1,
            'starts_at' => GameClock::now()->toIso8601ZuluString()]);
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/start")->assertOk();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_a_season_with_no_human_never_fields_a_short_or_unfit_side(): void
    {
        Leaving::leave(LeagueMembership::where('user_id', $this->owner->id)->first(), 'resigned');
        $this->assertSame(0, DB::table('clubs')->where('league_id', $this->league['id'])->whereNotNull('user_id')->count());
        // Injuries and bans pile up on one club: it still fields eleven fit men.
        $club = DB::table('clubs')->where('league_id', $this->league['id'])->value('id');
        DB::table('players')->where('club_id', $club)->orderBy('id')->limit(5)->update(['injured_matches' => 9]);
        for ($i = 0; $i < 400 && DB::table('fixtures')->where('is_bye', false)->whereNotNull('home_id')->where('status', '!=', 'finished')->exists(); $i++) {
            Carbon::setTestNow(GameClock::now()->addSeconds(30));
            $this->artisan('matches:prepare');
            MatchRunner::step();
        }
        $this->assertFalse(DB::table('fixtures')->where('competition', 'league')->where('status', '!=', 'finished')->where('is_bye', false)->exists());
        $sheets = DB::table('fixture_sheets')->get();
        $this->assertGreaterThanOrEqual(12, $sheets->count());
        foreach ($sheets as $s) {
            $starters = array_filter(json_decode($s->starters, true));
            $this->assertCount(11, $starters);
            $this->assertCount(11, array_unique($starters));
            $this->assertSame([], array_intersect($starters, json_decode($s->bench, true)));
        }
        // The injured never started.
        $hurt = DB::table('players')->where('club_id', $club)->orderBy('id')->limit(5)->pluck('id')->all();
        foreach ($sheets->where('club_id', $club) as $s) {
            $this->assertSame([], array_intersect($hurt, json_decode($s->starters, true)));
        }
    }

    public function test_the_bot_never_reads_the_opponents_hidden_tactics(): void
    {
        // Play round 1, so each club has a locked sheet the next opponent can look at.
        for ($i = 0; $i < 40 && DB::table('fixtures')->where('round', 1)->where('competition', 'league')->where('status', '!=', 'finished')->exists(); $i++) {
            Carbon::setTestNow(GameClock::now()->addSeconds(30));
            $this->artisan('matches:prepare');
            MatchRunner::step();
        }
        $next = DB::table('fixtures')->where('competition', 'league')->where('round', 2)->where('is_bye', false)
            ->whereNot(fn ($q) => $q->where('home_id', $this->league['my_club_id'])->orWhere('away_id', $this->league['my_club_id']))->first();
        $bot = Club::find($next->home_id);
        $before = Bot::tacticsFor($bot, $next);
        // The opponent's hidden knobs (pressing, style, tempo, positions) change everywhere they are kept.
        $hidden = ['pressing' => 5, 'style' => 95, 'tempo' => 3, 'att' => 'only', 'mid' => 'push', 'def' => 'fullbacks'];
        foreach (DB::table('fixture_sheets')->where('club_id', $next->away_id)->get() as $s) {
            DB::table('fixture_sheets')->where('id', $s->id)->update(['tactics' => json_encode($hidden + json_decode($s->tactics, true))]);
        }
        DB::table('tactics')->updateOrInsert(['club_id' => $next->away_id], $hidden + ['plan' => 'passing', 'tackling' => 1, 'trap' => 0, 'marking' => 'zone']);
        $this->assertSame($before, Bot::tacticsFor($bot, $next));
        $this->assertSame(['public', 'form'], array_keys(Bot::seen($next->away_id, $next->id)));
        $this->assertSame(['tackling', 'marking', 'plan', 'trap'], array_keys(Bot::seen($next->away_id, $next->id)['public']));
    }

    public function test_each_personality_plays_its_own_way(): void
    {
        $seen = ['public' => null, 'form' => []];
        $t = fn ($p) => Bot::tactics($p, 8000, 8000, $seen, 1);
        $this->assertSame(3, $t('hard')['tackling']);
        $this->assertSame('counter', $t('defenders')['plan']);
        $this->assertGreaterThan($t('giants')['pressing'], $t('pressers')['pressing']);
        $this->assertSame('wings', $t('wingers')['plan']);
        $this->assertSame('fullbacks', $t('wingers')['def']);
        // Stronger attacks more; weaker sits deeper; the adaptive bot counters a much stronger side.
        $this->assertGreaterThan(Bot::tactics('giants', 7000, 9000, $seen, 1)['style'], Bot::tactics('giants', 9000, 7000, $seen, 1)['style']);
        $this->assertSame('counter', Bot::tactics('adaptive', 6000, 9500, $seen, 1)['plan']);
        // Against an offside trap the adaptive bot plays no long balls.
        foreach (range(1, 30) as $seed) {
            $this->assertNotContains(Bot::tactics('adaptive', 8000, 8000, ['public' => ['tackling' => 1, 'marking' => 'zone', 'plan' => 'passing', 'trap' => 1], 'form' => []], $seed)['plan'], ['long', 'counter']);
        }
    }
}
