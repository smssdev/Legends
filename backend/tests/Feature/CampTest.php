<?php

namespace Tests\Feature;

use App\League\ClubLedger;
use App\League\LeagueMatch;
use App\League\TeamSheet;
use App\Models\Club;
use App\Models\User;
use App\Support\GameClock;
use App\Training\Camp;
use App\Training\Gain;
use App\Training\SecretTraining;
use App\Training\Training;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** The training camp and secret training, item by item of their specs in docs/features/ [Sprint 28]. */
class CampTest extends TestCase
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
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'rounds_per_day' => 1, 'round_times' => ['21:00']]);
        $this->mine = $this->league['my_club_id'];
        config(['game.camp.min_left' => 12]);   // the test squads have 18 players
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function url(string $path = ''): string
    {
        return "/api/v1/leagues/{$this->league['id']}/training{$path}";
    }

    /** My players with room to grow. */
    private function growers(int $n): array
    {
        return DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')
            ->where('players.club_id', $this->mine)->whereColumn('master_players.potential', '>', 'players.overall')
            ->orderBy('players.id')->limit($n)->pluck('players.id')->all();
    }

    private function send(array $ids, string $level = 'good', int $days = 1, string $key = 'k1')
    {
        return $this->actingAs($this->owner)->postJson($this->url('/camp'), ['player_ids' => $ids, 'level' => $level, 'days' => $days, 'idempotency_key' => $key]);
    }

    public function test_camp_1_sending_pays_once_and_the_limits_hold(): void
    {
        $ids = $this->growers(3);
        $before = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        $price = Camp::price($this->league['id'], 'good', 3, 2);
        $this->assertSame(Training::cost($this->league['id']) * 3 * 6 * 2, $price);
        $this->send($ids, days: 2)->assertOk()->assertJsonPath('camp.current.status', 'active');
        $this->send($ids, days: 2)->assertOk();
        $this->assertSame($before - $price, (int) DB::table('clubs')->where('id', $this->mine)->value('balance'));
        $this->assertSame(1, DB::table('training_camps')->count());

        $this->send($this->growers(1), key: 'k2')->assertConflict()->assertJsonPath('message', 'لديك معسكر جارٍ، انتظر عودة لاعبيه.');
        DB::table('training_camps')->update(['status' => 'done']);
        $all = DB::table('players')->where('club_id', $this->mine)->pluck('id')->all();
        $this->send(array_slice($all, 0, 6), key: 'k3')->assertUnprocessable();
        config(['game.camp.min_left' => 16]);
        $this->send(array_slice($all, 0, 3), key: 'k4')->assertUnprocessable()->assertJsonPath('message', 'يجب أن يبقى 16 لاعباً على الأقل خارج المعسكر.');
        config(['game.camp.min_left' => 12]);
        ClubLedger::post($this->mine, 'wages', -100_000_000, 'debt');
        $this->send($ids, key: 'k5')->assertConflict()->assertJsonPath('message', 'رصيد النادي لا يكفي.');
    }

    public function test_camp_2_and_4_sessions_run_with_the_coach_away_at_the_levels_pace_and_follow_the_season(): void
    {
        $ids = $this->growers(2);
        DB::table('players')->where('id', $ids[0])->update(['training_progress' => 9500]);
        $this->send($ids, 'elite')->assertOk();
        $camp = DB::table('training_camps')->first();
        $interval = Training::interval($this->league['id']);
        $this->assertSame($interval * 3, (int) Carbon::parse($camp->created_at, 'UTC')->diffInSeconds(Carbon::parse($camp->ends_at, 'UTC')));

        Carbon::setTestNow(GameClock::now()->addSeconds($interval));
        $this->artisan('training:tick')->assertSuccessful();
        // +1 at the full bar, and he stays at the camp, his bar starting again.
        $this->assertSame(1, (int) DB::table('players')->where('id', $ids[0])->value('training_bonus'));
        $this->assertSame('active', DB::table('training_camps')->value('status'));
        $p = DB::table('players')->where('id', $ids[1])->first();
        $this->assertGreaterThan(0, (int) $p->training_progress);

        // The elite step is twice an ordinary session's.
        $gain = Gain::fromConfig();
        $this->assertSame(intdiv($gain->step($p->overall, "camp:{$camp->id}:{$ids[1]}:1") * 20000, 10000), (int) $p->training_progress);
    }

    public function test_camp_3_they_miss_matches_and_training_then_come_back_on_time_with_a_message(): void
    {
        $ids = $this->growers(2);
        Training::add($this->mine, $ids[0]);
        $this->send($ids, 'basic')->assertOk();
        $this->assertSame(0, DB::table('training_slots')->count());
        $squad = collect(TeamSheet::squad(Club::find($this->mine)))->keyBy('id');
        $this->assertTrue($squad[$ids[0]]['unavailable']);
        $this->assertFalse($squad[$this->growers(3)[2]]['unavailable']);
        $card = collect($this->getJson("/api/v1/leagues/{$this->league['id']}/team")->json('players'))->firstWhere('id', $ids[0]);
        $this->assertTrue($card['in_camp']);
        $this->assertFalse($card['available']);
        $this->postJson($this->url(), ['player_id' => $ids[1]])->assertConflict()->assertJsonPath('message', 'اللاعب في المعسكر حتى يعود.');

        Carbon::setTestNow(GameClock::now()->addDays(2));
        $this->artisan('training:tick')->assertSuccessful();
        $this->assertSame('done', DB::table('training_camps')->value('status'));
        $this->assertSame(3, (int) DB::table('training_camps')->value('sessions_done'));
        $this->assertSame([], Camp::awayIds($this->mine));
        $this->assertSame('عاد اللاعبون من المعسكر', $this->getJson('/api/v1/messages')->json('messages.0.title'));
    }

    public function test_secret_1_ordering_pays_once_until_the_lock_and_five_a_season(): void
    {
        $f = SecretTraining::nextFixture($this->mine);
        $before = (int) DB::table('clubs')->where('id', $this->mine)->value('balance');
        $page = $this->actingAs($this->owner)->postJson($this->url('/secret'), ['line' => 'mid'])->assertOk();
        $page->assertJsonPath('secret.fixture.line', 'mid')->assertJsonPath('secret.used', 1);
        $this->assertSame($before - SecretTraining::cost($this->league['id']), (int) DB::table('clubs')->where('id', $this->mine)->value('balance'));
        $this->postJson($this->url('/secret'), ['line' => 'att'])->assertConflict()->assertJsonPath('message', 'طلبت تدريباً سرياً لهذه المباراة.');

        DB::table('secret_trainings')->delete();
        DB::table('fixtures')->where('id', $f->id)->update(['status' => 'locked']);
        $this->postJson($this->url('/secret'), ['line' => 'att'])->assertConflict()->assertJsonPath('message', 'قُفلت التشكيلة، فلا تدريب سري لهذه المباراة.');

        DB::table('fixtures')->where('id', $f->id)->update(['status' => 'scheduled']);
        foreach (range(1, 5) as $i) {
            DB::table('secret_trainings')->insert(['club_id' => $this->mine, 'fixture_id' => DB::table('fixtures')->where('id', '!=', $f->id)->skip($i)->value('id'),
                'season_id' => $f->season_id, 'line' => 'gk', 'cost' => 1]);
        }
        $this->postJson($this->url('/secret'), ['line' => 'att'])->assertConflict()->assertJsonPath('message', 'استخدمت التدريب السري 5 مرات هذا الموسم.');
    }

    public function test_secret_2_and_3_the_line_plays_that_match_only_three_up_and_the_opponent_never_sees_it(): void
    {
        $f = SecretTraining::nextFixture($this->mine);
        $this->actingAs($this->owner)->postJson($this->url('/secret'), ['line' => 'def'])->assertOk();
        // The opponent's coach sees nothing of it.
        $rival = $this->approvedCoach($this->owner, $this->league);
        $theirs = $f->home_id === $this->mine ? $f->away_id : $f->home_id;
        $this->actingAs($rival)->postJson("/api/v1/leagues/{$this->league['id']}/clubs/{$theirs}/claim")->assertCreated();
        $this->assertStringNotContainsString('secret', $this->actingAs($rival)->getJson("/api/v1/leagues/{$this->league['id']}/team/next-match")->getContent());

        Carbon::setTestNow(Carbon::parse($f->scheduled_at, 'UTC')->subMinutes(5));
        $this->artisan('matches:prepare')->assertSuccessful();
        $state = LeagueMatch::state(DB::table('fixtures')->find($f->id), 1);
        $side = $f->home_id === $this->mine ? 'home' : 'away';
        $base = DB::table('players')->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('players.club_id', $this->mine)
            ->get(['players.id', 'players.overall', 'master_players.line', 'master_players.def'])->keyBy('id');
        foreach ($state['teams'][$side]['players'] as $p) {
            $b = $base[$p['id']];
            $this->assertSame($b->line === 'def' ? min(99, $b->overall + 3) : (int) $b->overall, $p['a']['ovr'], $b->line);
        }
        foreach ($state['teams'][$side === 'home' ? 'away' : 'home']['players'] as $p) {
            $this->assertSame((int) DB::table('players')->where('id', $p['id'])->value('overall'), $p['a']['ovr']);
        }
    }
}
