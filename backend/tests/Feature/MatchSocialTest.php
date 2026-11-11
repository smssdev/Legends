<?php

namespace Tests\Feature;

use App\Events\MatchSocialPosted;
use App\League\MatchRunner;
use App\Models\User;
use App\Support\GameClock;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Event;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [X24] The live broadcast: floating reactions, boos and cheers with a cool-down, and the side chat. */
class MatchSocialTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private object $match;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create(['name' => 'سليمان']);
        $league = $this->makeLeague($this->owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1,
            'starts_at' => GameClock::now()->toIso8601ZuluString()]);
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$league['id']}/start")->assertOk();
        $mine = $league['my_club_id'];
        $fixture = DB::table('fixtures')->where('competition', 'league')->where('round', 1)->where('is_bye', false)
            ->where(fn ($q) => $q->where('home_id', $mine)->orWhere('away_id', $mine))->first();
        Carbon::setTestNow(Carbon::parse($fixture->scheduled_at, 'UTC'));
        MatchRunner::step();
        $this->match = DB::table('matches')->where('fixture_id', $fixture->id)->first();
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function later(int $ms): void
    {
        Carbon::setTestNow(GameClock::now()->addMilliseconds($ms));
    }

    public function test_reactions_float_for_every_viewer_with_a_pace(): void
    {
        $url = "/api/v1/matches/{$this->match->id}";
        $this->postJson("{$url}/reactions", ['key' => 'fire'])->assertCreated()->assertJsonPath('who', 'سليمان')->assertJsonPath('key', 'fire');
        $this->postJson("{$url}/reactions", ['key' => 'clap'])->assertStatus(422);
        $this->later(1500);
        $this->postJson("{$url}/reactions", ['key' => 'clap'])->assertCreated();
        $this->postJson("{$url}/reactions", ['key' => 'nope'])->assertStatus(422);

        // A boo or a cheer: for one side, once in half a minute, apart from the emojis.
        $this->postJson("{$url}/reactions", ['key' => 'cheer'])->assertStatus(422);
        $this->postJson("{$url}/reactions", ['key' => 'cheer', 'target' => 'home'])->assertCreated()->assertJsonPath('target', 'home');
        $this->later(5000);
        $this->postJson("{$url}/reactions", ['key' => 'boo', 'target' => 'away'])->assertStatus(422);
        $this->postJson("{$url}/reactions", ['key' => 'wow'])->assertCreated();
        $this->later(26000);
        $this->postJson("{$url}/reactions", ['key' => 'boo', 'target' => 'away'])->assertCreated();

        $live = $this->getJson("{$url}/live?since=0")->assertOk()->json();
        $this->assertSame(['fire', 'clap', 'cheer', 'wow', 'boo'], array_column($live['reactions'], 'key'));
        $this->assertSame([1, 2, 3, 4, 5], array_column($live['reactions'], 'id'));
    }

    public function test_the_side_chat_is_for_the_league_while_the_match_is_live(): void
    {
        $url = "/api/v1/matches/{$this->match->id}";
        $this->postJson("{$url}/chat", ['body' => "  يا   سلام\n على الهدف  "])->assertCreated()->assertJsonPath('body', 'يا سلام على الهدف');
        $this->postJson("{$url}/chat", ['body' => 'ثانية'])->assertStatus(422);
        $this->later(2500);
        $this->postJson("{$url}/chat", ['body' => str_repeat('ا', 141)])->assertStatus(422);
        $this->postJson("{$url}/chat", ['body' => '   '])->assertStatus(422);
        $this->postJson("{$url}/chat", ['body' => 'ثانية'])->assertCreated();
        $this->assertSame(['يا سلام على الهدف', 'ثانية'], array_column($this->getJson("{$url}/live?since=0")->json('chat'), 'body'));

        // Outside the league: nothing.
        $this->actingAs(User::factory()->create())->postJson("{$url}/chat", ['body' => 'مرحبا'])->assertNotFound();
        $this->actingAs($this->owner);
        DB::table('matches')->where('id', $this->match->id)->update(['status' => 'done']);
        $this->later(3000);
        $this->postJson("{$url}/chat", ['body' => 'بعد النهاية'])->assertStatus(409);
        $this->postJson("{$url}/reactions", ['key' => 'fire'])->assertStatus(409);
    }

    /** [Sprint 53 B3] A chat line and a reaction go out on the match's channel at once, as the poll gives them. */
    public function test_the_chat_and_the_reactions_are_pushed_on_the_match_channel(): void
    {
        Event::fake([MatchSocialPosted::class]);
        $url = "/api/v1/matches/{$this->match->id}";
        $line = $this->postJson("{$url}/chat", ['body' => 'هيا'])->assertCreated()->json();
        $this->postJson("{$url}/reactions", ['key' => 'fire'])->assertCreated();
        Event::assertDispatched(MatchSocialPosted::class, fn ($e) => $e->broadcastAs() === 'chat' && $e->item === $line
            && $e->broadcastOn()->name === "private-match.{$this->match->id}");
        Event::assertDispatched(MatchSocialPosted::class, fn ($e) => $e->broadcastAs() === 'reaction' && $e->item['key'] === 'fire');
    }
}
