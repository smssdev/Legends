<?php

namespace Tests\Feature;

use App\League\MatchRunner;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 48 T1] The squad's season: each player's goals and rating by round, and the league's transfers. */
class SquadSeasonTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_the_squad_season_gives_the_played_rounds_and_the_league_transfers(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1, 'starts_at' => GameClock::now()->toIso8601ZuluString()]);
        $this->actingAs($owner)->postJson("/api/v1/leagues/{$league['id']}/start")->assertOk();
        $url = "/api/v1/leagues/{$league['id']}/team/season";
        $mine = $league['my_club_id'];

        // Before any match: nothing played, no transfer.
        $empty = $this->getJson($url)->assertOk()->json();
        $this->assertSame(0, $empty['rounds']);
        $this->assertSame([], $empty['players']);
        $this->assertSame([], $empty['transfers']);

        // Round 1 played at once (the server was off past the live window).
        $fixture = DB::table('fixtures')->where('competition', 'league')->where('round', 1)->where('is_bye', false)
            ->where(fn ($q) => $q->where('home_id', $mine)->orWhere('away_id', $mine))->first();
        Carbon::setTestNow(Carbon::parse($fixture->scheduled_at, 'UTC')->addMinutes(11));
        MatchRunner::step();
        $this->assertSame('finished', DB::table('fixtures')->where('id', $fixture->id)->value('status'));

        // A move in the league this season: one of my players to another club.
        $season = DB::table('seasons')->where('league_id', $league['id'])->orderByDesc('id')->value('id');
        $other = DB::table('clubs')->where('league_id', $league['id'])->where('id', '!=', $mine)->value('id');
        $moved = DB::table('players')->where('club_id', $mine)->orderBy('id')->value('id');
        DB::table('player_moves')->insert(['season_id' => $season, 'player_id' => $moved, 'from_club_id' => $mine, 'to_club_id' => $other,
            'price' => 1_500_000, 'created_at' => GameClock::now()]);

        $data = $this->getJson($url)->assertOk()->json();
        $this->assertSame(1, $data['rounds']);
        $sheet = collect(json_decode(DB::table('match_stats')->where('club_id', $mine)->value('players'), true))->where('played', true);
        $this->assertCount($sheet->count(), $data['players'], 'every player who played, and only them');
        $this->assertSame($sheet->sum('goals'), collect($data['players'])->sum('goals'));
        foreach ($data['players'] as $id => $p) {
            $this->assertSame(1, $p['played']);
            $this->assertSame((int) $sheet->firstWhere('id', (int) $id)['rating'], $p['ratings']['1']);
            $this->assertSame($p['ratings']['1'], $p['average']);
        }
        $this->assertCount(1, $data['transfers']);
        $move = $data['transfers'][0];
        $this->assertSame($moved, $move['player_id']);
        $this->assertSame(1_500_000, $move['price']);
        $names = DB::table('clubs')->whereIn('id', [$mine, $other])->pluck('name', 'id');
        $this->assertSame([$names[$mine], $names[$other]], [$move['from'], $move['to']]);
    }

    public function test_only_a_member_with_a_club_sees_it(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $league = $this->makeLeague(User::factory()->create());
        $this->actingAs(User::factory()->create())->getJson("/api/v1/leagues/{$league['id']}/team/season")->assertForbidden();
    }
}
