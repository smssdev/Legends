<?php

namespace Tests\Feature;

use App\Messenger\LiveFeed;
use App\Messenger\Messenger;
use App\Models\User;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 69] The match steered from the bot, training, the daily tasks, predictions, «@bot» anywhere, the joined chat and the round's stars. */
class MessengerPlusTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    private object $club;

    private int $update = 1;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        config(['services.telegram.token' => '123:tg-token', 'services.telegram.secret' => 'tg-secret', 'services.telegram.username' => 'GlmBot',
            'services.gemini.key' => null, 'app.frontend_url' => 'https://game.test', 'app.url' => 'https://game.test']);
        Http::fake(['api.telegram.org/*' => Http::response(['ok' => true, 'result' => []])]);
        $this->owner = User::factory()->create(['name' => 'Sliman', 'locale' => 'ar']);
        $this->league = $this->makeLeague($this->owner);
        $this->club = DB::table('clubs')->where('league_id', $this->league['id'])->where('user_id', $this->owner->id)->first();
        $this->send(['message' => ['chat' => ['id' => 777, 'type' => 'private'], 'from' => ['id' => 777], 'text' => '/start '.Messenger::code($this->owner->id)['code']]]);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function send(array $update)
    {
        return $this->withHeader('X-Telegram-Bot-Api-Secret-Token', 'tg-secret')->postJson('/api/v1/messenger/telegram', ['update_id' => $this->update++] + $update)->assertOk();
    }

    private function say(string $text, int $chat = 777, string $type = 'private', int $from = 777)
    {
        return $this->send(['message' => ['chat' => ['id' => $chat, 'type' => $type], 'from' => ['id' => $from], 'text' => $text]]);
    }

    private function tap(string $data)
    {
        return $this->send(['callback_query' => ['id' => 'cb', 'data' => $data, 'from' => ['id' => 777], 'message' => ['chat' => ['id' => 777, 'type' => 'private']]]]);
    }

    private function sent(): array
    {
        return Http::recorded()->filter(fn ($r) => str_ends_with($r[0]->url(), '/sendMessage'))->map(fn ($r) => $r[0]->data())->values()->all();
    }

    private function last(): array
    {
        return last($this->sent()) ?: [];
    }

    /** Every callback of the last message's buttons. */
    private function buttons(): array
    {
        return collect($this->last()['reply_markup']['inline_keyboard'] ?? [])->flatten(1)->pluck('callback_data')->all();
    }

    public function test_a_player_is_put_in_training_from_the_bot(): void
    {
        $this->say('التدريب');
        $this->assertContains("pick:{$this->club->id}:def", $this->buttons());
        $this->tap("pick:{$this->club->id}:def");
        $choice = collect($this->buttons())->first();
        $this->assertStringStartsWith('ask:train:', $choice);
        $player = (int) substr($choice, strlen('ask:train:'));
        $this->tap($choice);
        $this->assertStringContainsString('في التدريب؟', $this->last()['text']);
        $this->assertFalse(DB::table('training_slots')->where('player_id', $player)->exists());
        $this->tap("do:train:{$player}");
        $this->assertTrue(DB::table('training_slots')->where('player_id', $player)->exists());
    }

    public function test_a_finished_daily_task_pays_from_the_bot_once(): void
    {
        DB::table('lineups')->insert(['club_id' => $this->club->id, 'formation' => '4-4-2A', 'created_at' => now(), 'updated_at' => now()]);
        $this->say('مهامي');
        $this->assertStringContainsString('ضبط الفريق', $this->last()['text']);
        $this->assertContains("claim:{$this->club->id}:lineup", $this->buttons());
        $coins = Wallet::balance($this->owner->id);
        $this->tap("claim:{$this->club->id}:lineup");
        $this->assertSame($coins + (int) config('game.daily_tasks.lineup'), Wallet::balance($this->owner->id));
        $this->tap("claim:{$this->club->id}:lineup");
        $this->assertSame($coins + (int) config('game.daily_tasks.lineup'), Wallet::balance($this->owner->id));
    }

    public function test_a_match_is_predicted_from_the_bot(): void
    {
        $this->say('توقعاتي');
        $pick = collect($this->buttons())->first(fn ($b) => str_ends_with((string) $b, ':draw'));
        $this->assertNotNull($pick);
        $this->tap($pick);
        $this->assertStringContainsString('حُفظ توقعك', $this->last()['text']);
        $this->assertSame('draw', DB::table('match_predictions')->where('user_id', $this->owner->id)->value('pick'));
    }

    public function test_the_live_match_is_steered_from_the_bot(): void
    {
        $f = DB::table('fixtures')->where(fn ($q) => $q->where('home_id', $this->club->id)->orWhere('away_id', $this->club->id))->whereNotNull('away_id')->first();
        // A break at minute 15: the quick orders and «جاهز».
        LiveFeed::minute($f, 41, ['cfg' => ['match' => ['windows' => [15, 30, 60, 75]]], 'teams' => ['home' => ['players' => []], 'away' => ['players' => []]]],
            ['minute' => [15, 0], 'period' => 1, 'score' => ['home' => 0, 'away' => 0], 'at' => 0, 'moment' => ['ms' => 0], 'events' => []]);
        $this->assertStringContainsString('توقف الدقيقة 15', $this->last()['text']);
        $this->assertContains('q:41:0', $this->buttons());
        $this->assertContains('ready:41', $this->buttons());

        // Not his match (it does not exist): refused.
        $this->tap('q:41:0');
        $this->assertStringContainsString('ليست لك', $this->last()['text']);
        // His live match: the order goes into the next minute, as from the match screen.
        $id = DB::table('matches')->insertGetId(['fixture_id' => $f->id, 'seed' => 1, 'engine_version' => 1, 'config_snapshot' => '{}', 'initial_state' => '{}',
            'state' => json_encode(['tick' => 15, 'finished' => false]), 'tick' => 15, 'mode' => 'live', 'status' => 'live', 'started_at' => now(), 'created_at' => now(), 'updated_at' => now()]);
        $this->tap("q:{$id}:0");
        $this->assertStringContainsString('هجوم كامل', $this->last()['text']);
        $action = DB::table('match_actions')->where('match_id', $id)->first();
        $this->assertSame(16, (int) $action->target_tick);
        $this->assertSame('tactics', json_decode($action->action, true)['type']);
        // «عودة للخطة»: the club's own saved tactics.
        $back = count(config('game.quick_orders')) - 1;
        $this->tap("q:{$id}:{$back}");
        $this->assertNotNull(json_decode(DB::table('match_actions')->where('match_id', $id)->orderByDesc('id')->value('action'), true)['tactics']);
    }

    public function test_at_bot_in_any_chat_offers_the_results_the_table_and_an_invitation(): void
    {
        $this->send(['inline_query' => ['id' => 'iq1', 'from' => ['id' => 777], 'query' => '']]);
        $answer = Http::recorded()->first(fn ($r) => str_ends_with($r[0]->url(), '/answerInlineQuery'))[0]->data();
        $ids = array_column($answer['results'], 'id');
        $this->assertContains("table:{$this->league['id']}", $ids);
        $this->assertContains('invite', $ids);
        $this->assertStringContainsString('register?ref=', $answer['results'][array_search('invite', $ids)]['reply_markup']['inline_keyboard'][0][0]['url']);
        // Someone not linked: the invitation alone.
        $this->send(['inline_query' => ['id' => 'iq2', 'from' => ['id' => 999], 'query' => 'hi']]);
        $answer = Http::recorded()->filter(fn ($r) => str_ends_with($r[0]->url(), '/answerInlineQuery'))->last()[0]->data();
        $this->assertSame(['invite'], array_column($answer['results'], 'id'));
    }

    public function test_the_owner_joins_the_group_to_the_game_chat_both_ways(): void
    {
        $this->say("/league {$this->league['code']}", -100, 'supergroup');
        // Off by default: the members' talk is not read.
        $this->say('مرحبا يا شباب', -100, 'supergroup');
        $this->assertFalse(DB::table('chat_group_messages')->where('body', 'مرحبا يا شباب')->exists());

        $this->say('/chat on', -100, 'supergroup');
        $this->say('مرحبا يا شباب', -100, 'supergroup');
        $group = DB::table('chat_groups')->where('league_id', $this->league['id'])->value('id');
        $this->assertSame((int) $this->owner->id, (int) DB::table('chat_group_messages')->where('chat_group_id', $group)->where('body', 'مرحبا يا شباب')->value('user_id'));
        // Carried in, never carried back out.
        $this->assertFalse(collect($this->sent())->contains(fn ($m) => str_contains($m['text'], 'Sliman: مرحبا يا شباب')));
        // Someone not linked writes in the group: not carried.
        $this->say('من أنا؟', -100, 'supergroup', 999);
        $this->assertFalse(DB::table('chat_group_messages')->where('body', 'من أنا؟')->exists());

        // From the game to the group, under the writer's name.
        $this->actingAs($this->owner)->postJson("/api/v1/groups/{$group}/messages", ['body' => 'أهلاً من اللعبة'])->assertSuccessful();
        $this->assertSame('Sliman: أهلاً من اللعبة', $this->last()['text']);
        $this->assertSame('-100', (string) $this->last()['chat_id']);
    }
}
