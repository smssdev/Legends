<?php

namespace Tests\Feature;

use App\Messenger\LeagueGroups;
use App\Messenger\LiveFeed;
use App\Messenger\Messenger;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 68] More of the Telegram bot: the readings, the actions asked twice, the live match, the daily summary, the groups' goals and polls. */
class MessengerMoreTest extends TestCase
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
            'services.gemini.key' => null, 'app.frontend_url' => 'https://game.test']);
        Http::fake([
            'api.telegram.org/*/sendPoll' => Http::response(['ok' => true, 'result' => ['message_id' => 55]]),
            'api.telegram.org/*' => Http::response(['ok' => true, 'result' => []]),
        ]);
        $this->owner = User::factory()->create(['name' => 'Sliman', 'locale' => 'ar']);
        $this->league = $this->makeLeague($this->owner);
        $this->club = DB::table('clubs')->where('league_id', $this->league['id'])->where('user_id', $this->owner->id)->first();
        $code = Messenger::code($this->owner->id)['code'];
        $this->telegram("/start {$code}");
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function telegram(string $text, int $chat = 777, string $type = 'private', ?int $from = null)
    {
        return $this->withHeader('X-Telegram-Bot-Api-Secret-Token', 'tg-secret')->postJson('/api/v1/messenger/telegram', ['update_id' => $this->update++,
            'message' => ['chat' => ['id' => $chat, 'type' => $type], 'from' => ['id' => $from ?? $chat], 'text' => $text]]);
    }

    private function tap(string $data, int $chat = 777)
    {
        return $this->withHeader('X-Telegram-Bot-Api-Secret-Token', 'tg-secret')->postJson('/api/v1/messenger/telegram', ['update_id' => $this->update++,
            'callback_query' => ['id' => 'cb'.$this->update, 'data' => $data, 'from' => ['id' => $chat], 'message' => ['chat' => ['id' => $chat, 'type' => 'private']]]]);
    }

    /** The messages sent (not the button answers, polls or menus set), in order. */
    private function sent(): array
    {
        return Http::recorded()->filter(fn ($r) => str_ends_with($r[0]->url(), '/sendMessage'))->map(fn ($r) => $r[0]->data())->values()->all();
    }

    private function lastText(): string
    {
        return (string) (last($this->sent())['text'] ?? '');
    }

    public function test_the_new_readings(): void
    {
        $player = DB::table('players')->where('club_id', $this->club->id)->orderBy('id')->first();
        DB::table('players')->where('id', $player->id)->update(['injured_matches' => 2]);
        $name = DB::table('master_players')->where('id', $player->master_player_id)->value('name');
        $this->telegram('فريقي');
        $this->assertStringContainsString("{$name}: مصاب (2 مباريات)", $this->lastText());
        $this->telegram('7');
        $this->assertStringContainsString('الحراسة: فارغة', $this->lastText());
        $this->telegram('/fixtures');
        $this->assertStringContainsString($this->club->name, $this->lastText());
        $this->telegram('الهدافون');
        $this->assertStringContainsString('لا أهداف بعد', $this->lastText());
        $this->telegram('رسائلي');
        $this->assertNotSame('', $this->lastText());
    }

    public function test_an_offer_is_rejected_from_the_bot_after_asking(): void
    {
        $other = DB::table('clubs')->where('league_id', $this->league['id'])->where('id', '!=', $this->club->id)->orderBy('id')->first();
        $season = DB::table('seasons')->where('league_id', $this->league['id'])->value('id');
        $offer = DB::table('transfer_offers')->insertGetId(['league_id' => $this->league['id'], 'season_id' => $season, 'from_club_id' => $other->id,
            'to_club_id' => $this->club->id, 'money' => 5000, 'status' => 'pending', 'idempotency_key' => 'test-offer', 'expires_at' => now()->addDay(),
            'created_at' => now(), 'updated_at' => now()]);

        $this->telegram('العروض');
        $msg = last($this->sent());
        $this->assertStringContainsString("عرض من {$other->name}", $msg['text']);
        $this->assertSame("ask:reject:{$offer}", $msg['reply_markup']['inline_keyboard'][0][1]['callback_data']);
        // The first tap only asks.
        $this->tap("ask:reject:{$offer}");
        $this->assertStringContainsString('ترفض هذا العرض؟', $this->lastText());
        $this->assertSame('pending', DB::table('transfer_offers')->where('id', $offer)->value('status'));
        $this->tap("do:reject:{$offer}");
        $this->assertSame('رُفض العرض.', $this->lastText());
        $this->assertSame('rejected', DB::table('transfer_offers')->where('id', $offer)->value('status'));
        // Another account's chat cannot decide it, whatever its button says.
        $stranger = User::factory()->create();
        $this->telegram('/start '.Messenger::code($stranger->id)['code'], 888);
        $this->tap("do:accept:{$offer}", 888);
        $this->assertStringContainsString('ليس لك', $this->lastText());
    }

    public function test_improve_sets_the_automatic_lineup_before_the_lock(): void
    {
        DB::table('lineups')->insert(['club_id' => $this->club->id, 'formation' => '4-4-2A', 'created_at' => now(), 'updated_at' => now()]);
        $this->telegram('تحسين');
        $this->assertSame("ask:fix:{$this->club->id}", last($this->sent())['reply_markup']['inline_keyboard'][0][0]['callback_data']);
        $this->tap("do:fix:{$this->club->id}");
        $this->assertStringContainsString('التلقائية الأفضل', $this->lastText());
        $this->assertFalse(DB::table('lineups')->where('club_id', $this->club->id)->exists());
    }

    public function test_the_live_match_reaches_the_coach_and_the_group_unless_off(): void
    {
        $this->telegram("/league {$this->league['code']}", -100, 'supergroup', 777);
        $f = DB::table('fixtures')->where(fn ($q) => $q->where('home_id', $this->club->id)->orWhere('away_id', $this->club->id))->whereNotNull('away_id')->first();
        $state = ['teams' => ['home' => ['players' => [['id' => 9, 'name' => 'Salah']]], 'away' => ['players' => []]]];
        $tick = ['minute' => 23, 'score' => ['home' => 1, 'away' => 0], 'at' => 0, 'moment' => ['ms' => 0],
            'events' => [['type' => 'goal', 'team' => 'home', 'scorer' => 9, 'score' => ['home' => 1, 'away' => 0]], ['type' => 'card', 'team' => 'away', 'player' => 1, 'color' => 'yellow']]];
        $before = count($this->sent());
        LiveFeed::minute($f, 41, $state, $tick);
        $new = array_slice($this->sent(), $before);
        // The coach (with the match's link) and the group, the yellow card to nobody.
        $this->assertCount(2, $new);
        $this->assertStringContainsString('هدف! Salah', $new[0]['text']);
        $this->assertStringContainsString('الدقيقة 23', $new[0]['text']);
        $this->assertSame('https://game.test/live/41', $new[0]['reply_markup']['inline_keyboard'][0][0]['url']);
        $this->assertSame('-100', (string) $new[1]['chat_id']);

        // «المباشر إيقاف» and «/goals off»: nothing more.
        $this->telegram('المباشر إيقاف');
        $this->telegram('/goals off', -100, 'supergroup', 777);
        $before = count($this->sent());
        LiveFeed::minute($f, 41, $state, $tick);
        $this->assertCount($before, $this->sent());
    }

    public function test_the_daily_summary_comes_once_at_the_chosen_hour(): void
    {
        $this->telegram('ملخص 13');
        $this->assertStringContainsString('الساعة 13:00', $this->lastText());
        // 10:00 UTC is 12:00 or 13:00 in Cairo by the season: the hour is taken from Cairo's clock.
        $hour = Carbon::now('Africa/Cairo')->hour;
        DB::table('messenger_links')->update(['daily_hour' => $hour]);
        $before = count($this->sent());
        $this->artisan('messenger:daily')->assertSuccessful();
        $this->assertCount($before + 1, $this->sent());
        $this->assertStringContainsString('صباح الخير يا مدرب', $this->lastText());
        $this->artisan('messenger:daily')->assertSuccessful();
        $this->assertCount($before + 1, $this->sent());
        $this->telegram('ملخص إيقاف');
        $this->assertNull(DB::table('messenger_links')->value('daily_hour'));
    }

    public function test_a_group_gets_a_poll_before_the_round_and_its_answer_after(): void
    {
        $this->telegram("/league {$this->league['code']}", -100, 'supergroup', 777);
        $season = DB::table('seasons')->where('league_id', $this->league['id'])->value('id');
        DB::table('fixtures')->where('season_id', $season)->where('competition', 'league')->where('round', 1)
            ->update(['status' => 'scheduled', 'scheduled_at' => Carbon::now()->addHours(2)]);
        $this->artisan('messenger:polls')->assertSuccessful();
        $this->artisan('messenger:polls')->assertSuccessful();
        $this->assertSame(1, DB::table('messenger_polls')->count());
        $poll = DB::table('messenger_polls')->first();
        $this->assertSame(55, (int) $poll->message_id);

        DB::table('fixtures')->where('id', $poll->fixture_id)->update(['status' => 'finished', 'home_goals' => 2, 'away_goals' => 2]);
        LeagueGroups::fixtureDone(DB::table('fixtures')->find($poll->fixture_id));
        LeagueGroups::fixtureDone(DB::table('fixtures')->find($poll->fixture_id));
        $this->assertTrue(Http::recorded()->contains(fn ($r) => str_ends_with($r[0]->url(), '/stopPoll')));
        $answer = last($this->sent());
        $this->assertStringContainsString('الإجابة: التعادل', $answer['text']);
        $this->assertSame(55, $answer['reply_parameters']['message_id']);
        $this->assertSame(1, collect($this->sent())->filter(fn ($m) => str_contains($m['text'], 'الإجابة'))->count());
    }
}
