<?php

namespace Tests\Feature;

use App\Messages\Inbox;
use App\Messenger\LeagueGroups;
use App\Messenger\Messenger;
use App\Messenger\Replies;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Factory;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 67] The game's bots on Telegram and WhatsApp: linking, the commands, the notifications, the groups, the channel. */
class MessengerTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private int $update = 1;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        config(['services.telegram.token' => 'tg-token', 'services.telegram.secret' => 'tg-secret', 'services.telegram.username' => 'GlmBot',
            'services.telegram.channel' => 'glm_news', 'services.whatsapp.token' => 'wa-token', 'services.whatsapp.phone_id' => '555',
            'services.whatsapp.app_secret' => 'wa-app-secret', 'services.whatsapp.verify' => 'wa-verify', 'services.whatsapp.number' => '+20 100 000 0000',
            'services.gemini.key' => null, 'app.frontend_url' => 'https://game.test']);
        Http::fake(['api.telegram.org/*' => Http::response(['ok' => true, 'result' => []]), 'graph.facebook.com/*' => Http::response(['messages' => [['id' => 'x']]])]);
        $this->template(full: true);
        $this->owner = User::factory()->create(['name' => 'Sliman', 'locale' => 'ar']);
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

    private function whatsapp(string $text, string $from = '201000000001')
    {
        $body = json_encode(['entry' => [['changes' => [['value' => ['messages' => [['from' => $from, 'id' => 'wamid.'.$this->update++, 'type' => 'text', 'text' => ['body' => $text]]]]]]]]]);

        return $this->call('POST', '/api/v1/messenger/whatsapp', [], [], [], ['CONTENT_TYPE' => 'application/json',
            'HTTP_X_HUB_SIGNATURE_256' => 'sha256='.hash_hmac('sha256', $body, 'wa-app-secret')], $body);
    }

    /** The texts the bot sent, on one platform, in order. */
    private function sent(string $host): array
    {
        // [Sprint 70] Not «read» on WhatsApp nor «typing» on Telegram: only messages.
        return Http::recorded()->filter(fn ($r) => str_contains($r[0]->url(), $host) && ! str_contains($r[0]->url(), 'answerCallbackQuery')
            && ! str_contains($r[0]->url(), 'sendChatAction') && ! isset($r[0]['status']))
            ->map(fn ($r) => $r[0]['text']['body'] ?? $r[0]['interactive']['body']['text'] ?? $r[0]['text'] ?? '')->values()->all();
    }

    private function linkTelegram(User $user, int $chat = 777): void
    {
        $code = $this->actingAs($user)->postJson('/api/v1/messenger/link', ['platform' => 'telegram'])->assertCreated()->json('code');
        $this->telegram("/start {$code}", $chat)->assertOk();
    }

    public function test_a_bot_without_its_keys_is_off_and_cannot_be_linked(): void
    {
        config(['services.telegram.token' => null, 'services.whatsapp.token' => null]);
        $this->actingAs($this->owner)->getJson('/api/v1/messenger')->assertOk()
            ->assertJsonPath('telegram.available', false)->assertJsonPath('whatsapp.available', false);
        $this->actingAs($this->owner)->postJson('/api/v1/messenger/link', ['platform' => 'telegram'])->assertStatus(409);
        $this->postJson('/api/v1/messenger/telegram', [])->assertNotFound();
    }

    public function test_telegram_links_with_the_profile_code_once(): void
    {
        $r = $this->actingAs($this->owner)->postJson('/api/v1/messenger/link', ['platform' => 'telegram'])->assertCreated();
        $code = $r->json('code');
        $this->assertSame("https://t.me/GlmBot?start={$code}", $r->json('url'));
        // Not from Telegram: refused.
        $this->postJson('/api/v1/messenger/telegram', ['update_id' => 1])->assertForbidden();

        $this->telegram("/start {$code}")->assertOk();
        $this->assertStringContainsString('تم الربط بحساب Sliman', $this->sent('api.telegram.org')[0]);
        $this->actingAs($this->owner)->getJson('/api/v1/messenger')->assertJsonPath('telegram.linked', true);
        // The code is spent: another chat cannot take it.
        $this->telegram("/start {$code}", 888);
        $this->assertStringContainsString('wrong or expired', last($this->sent('api.telegram.org')));
        $this->assertSame(1, DB::table('messenger_links')->count());
    }

    public function test_an_expired_code_does_not_link(): void
    {
        $code = Messenger::code($this->owner->id)['code'];
        Carbon::setTestNow('2026-10-22 10:16:00');
        $this->telegram($code);
        $this->assertSame(0, DB::table('messenger_links')->count());
    }

    public function test_the_commands_read_the_coach_clubs(): void
    {
        $league = $this->makeLeague($this->owner);
        $club = DB::table('clubs')->where('league_id', $league['id'])->where('user_id', $this->owner->id)->first();
        DB::table('clubs')->where('id', $club->id)->update(['balance' => 1234567]);
        $this->linkTelegram($this->owner);

        $this->telegram('رصيدي');
        $this->assertStringContainsString('1,234,567', last($this->sent('api.telegram.org')));
        $this->telegram('٢');
        $this->assertStringContainsString($league['name'], last($this->sent('api.telegram.org')));
        $this->telegram('/next@GlmBot');
        $this->assertStringContainsString($club->name, last($this->sent('api.telegram.org')));
        $this->telegram('1');
        $this->assertStringContainsString($club->name, last($this->sent('api.telegram.org')));
        // The menu comes with the buttons that stay under the chat [Sprint 68], and an answer with its own.
        $this->telegram('مساعدة');
        $menu = Http::recorded()->last()[0];
        $this->assertSame('مباراتي القادمة', $menu['reply_markup']['keyboard'][0][0]['text']);
        $this->telegram('1');
        $this->assertSame('next', Http::recorded()->last()[0]['reply_markup']['inline_keyboard'][0][0]['callback_data']);
    }

    public function test_a_question_without_a_link_is_answered_from_the_guide_with_how_to_link(): void
    {
        $this->telegram('كيف أنضم إلى دوري؟');
        $text = last($this->sent('api.telegram.org'));
        $this->assertStringContainsString('https://game.test/profile', $text);
        // A command that needs the account asks to link first.
        $this->telegram('رصيدي');
        $this->assertStringContainsString('اربط حسابك', last($this->sent('api.telegram.org')));
    }

    public function test_notifications_reach_telegram_unless_silenced_or_off(): void
    {
        $this->linkTelegram($this->owner);
        $before = count($this->sent('api.telegram.org'));
        Inbox::send($this->owner->id, 'offer_received', ['from' => 'Arsenal', 'players_in' => ['X'], 'players_out' => [], 'money' => 0]);
        $texts = $this->sent('api.telegram.org');
        $this->assertCount($before + 1, $texts);
        $this->assertStringContainsString('https://game.test/market', last($texts));

        // «إيقاف» silences the bot; the kind turned off in the settings never reaches it either.
        $this->telegram('إيقاف');
        $before = count($this->sent('api.telegram.org'));
        Inbox::send($this->owner->id, 'offer_received', ['from' => 'Arsenal', 'players_in' => ['X'], 'players_out' => [], 'money' => 0]);
        $this->assertCount($before, $this->sent('api.telegram.org'));
        $this->telegram('تشغيل');
        $this->actingAs($this->owner)->putJson('/api/v1/notifications', ['kinds' => ['offers' => false]])->assertOk();
        $before = count($this->sent('api.telegram.org'));
        Inbox::send($this->owner->id, 'offer_received', ['from' => 'Arsenal', 'players_in' => ['X'], 'players_out' => [], 'money' => 0]);
        $this->assertCount($before, $this->sent('api.telegram.org'));
    }

    public function test_a_blocked_bot_unlinks_the_chat(): void
    {
        $this->linkTelegram($this->owner);
        Http::swap(new Factory);
        Http::fake(['api.telegram.org/*' => Http::response(['ok' => false, 'description' => 'Forbidden: bot was blocked by the user'], 403)]);
        Inbox::send($this->owner->id, 'training_done', ['player' => 'X', 'overall' => 70]);
        $this->assertSame(0, DB::table('messenger_links')->count());
    }

    public function test_whatsapp_verifies_signs_and_writes_only_in_the_free_window(): void
    {
        $this->get('/api/v1/messenger/whatsapp?hub.mode=subscribe&hub.verify_token=wa-verify&hub.challenge=42')->assertOk()->assertSee('42');
        $this->get('/api/v1/messenger/whatsapp?hub.mode=subscribe&hub.verify_token=wrong&hub.challenge=42')->assertForbidden();
        // Unsigned: refused.
        $this->postJson('/api/v1/messenger/whatsapp', ['entry' => []])->assertForbidden();

        $r = $this->actingAs($this->owner)->postJson('/api/v1/messenger/link', ['platform' => 'whatsapp'])->assertCreated();
        $this->assertStringStartsWith('https://wa.me/201000000000?text=', $r->json('url'));
        $this->whatsapp('ربط '.$r->json('code'))->assertOk();
        $this->assertStringContainsString('تم الربط', last($this->sent('graph.facebook.com')));
        $this->assertSame('201000000001', DB::table('messenger_links')->where('platform', 'whatsapp')->value('chat_id'));

        // Within his 24 hours: free, so the notification goes.
        $before = count($this->sent('graph.facebook.com'));
        Inbox::send($this->owner->id, 'training_done', ['player' => 'X', 'overall' => 70]);
        $this->assertCount($before + 1, $this->sent('graph.facebook.com'));
        // A day later it would be a paid message: none.
        Carbon::setTestNow('2026-10-23 09:30:00');
        Inbox::send($this->owner->id, 'training_done', ['player' => 'X', 'overall' => 70]);
        $this->assertCount($before + 1, $this->sent('graph.facebook.com'));
        $this->actingAs($this->owner)->getJson('/api/v1/messenger')->assertJsonPath('whatsapp.window_open', false);
        // He writes again: the window opens, and he is answered.
        $this->whatsapp('3')->assertOk();
        $this->actingAs($this->owner)->getJson('/api/v1/messenger')->assertJsonPath('whatsapp.window_open', true);
        Inbox::send($this->owner->id, 'training_done', ['player' => 'X', 'overall' => 70]);
        $this->assertCount($before + 3, $this->sent('graph.facebook.com'));
    }

    public function test_a_message_resent_by_the_platform_is_answered_once(): void
    {
        $update = ['update_id' => 99, 'message' => ['chat' => ['id' => 5, 'type' => 'private'], 'from' => ['id' => 5], 'text' => 'help']];
        $this->withHeader('X-Telegram-Bot-Api-Secret-Token', 'tg-secret')->postJson('/api/v1/messenger/telegram', $update)->assertOk();
        $this->withHeader('X-Telegram-Bot-Api-Secret-Token', 'tg-secret')->postJson('/api/v1/messenger/telegram', $update)->assertOk();
        $this->assertCount(1, $this->sent('api.telegram.org'));
    }

    public function test_the_league_owner_links_a_telegram_group_that_gets_each_round_once(): void
    {
        $league = $this->makeLeague($this->owner);
        $this->linkTelegram($this->owner);
        // Someone else cannot link the league; group talk that is not a command is not read.
        $this->telegram("/league {$league['code']}", -100, 'supergroup', 999);
        $this->telegram('hello all', -100, 'supergroup', 777);
        $this->assertSame(0, DB::table('messenger_groups')->count());
        $this->telegram("/league {$league['code']}", -100, 'supergroup', 777);
        $this->assertSame($league['id'], DB::table('messenger_groups')->where('chat_id', '-100')->value('league_id'));

        $season = DB::table('seasons')->where('league_id', $league['id'])->value('id');
        DB::table('fixtures')->where('season_id', $season)->where('competition', 'league')->where('round', 1)->update(['status' => 'finished', 'home_goals' => 2, 'away_goals' => 1]);
        DB::table('seasons')->where('id', $season)->update(['rounds_played' => 1]);
        $before = count($this->sent('api.telegram.org'));
        LeagueGroups::roundDone($season);
        LeagueGroups::roundDone($season);
        $texts = $this->sent('api.telegram.org');
        // The results, then the round's stars [Sprint 69], once.
        $this->assertCount($before + 2, $texts);
        $this->assertStringContainsString('الجولة 1', $texts[$before]);
        $this->assertStringContainsString('2 - 1', $texts[$before]);
        $this->assertStringContainsString('نجوم الجولة 1', last($texts));

        $this->telegram('/unleague', -100, 'supergroup', 777);
        $this->assertSame(0, DB::table('messenger_groups')->count());
    }

    public function test_the_channel_gets_the_announcements_and_the_admins_copy_them(): void
    {
        Messenger::post('announcement', "موسم جديد\n\nيبدأ الجمعة");
        $post = Http::recorded()->last()[0];
        $this->assertSame('@glm_news', $post['chat_id']);
        $this->linkTelegram($this->owner);
        // Only an official account gets the channel's text; anyone else's «قناة» is a question.
        $this->telegram('قناة');
        $this->assertStringNotContainsString('يبدأ الجمعة', last($this->sent('api.telegram.org')));
        DB::table('users')->where('id', $this->owner->id)->update(['username' => config('game.account.official_usernames')[0]]);
        $this->telegram('قناة');
        $this->assertStringContainsString('يبدأ الجمعة', last($this->sent('api.telegram.org')));
    }

    public function test_the_words_and_codes_are_read_as_commands(): void
    {
        $this->assertSame('next', Replies::command('/next@GlmBot'));
        $this->assertSame('table', Replies::command('٢'));
        $this->assertSame('now', Replies::command('ماذا أفعل الآن؟'));
        $this->assertNull(Replies::command('كيف أدرب لاعباً'));
        $this->assertSame('AB3CDEFG', Replies::linkCode('ربط ab3cdefg'));
        // A word of eight letters with no digit is never a code.
        $this->assertNull(Replies::linkCode('STANDARD'));
    }

    public function test_every_page_can_open_the_bots_and_channels(): void
    {
        $this->getJson('/api/v1/health')->assertOk()
            ->assertJsonPath('bots.telegram', 'https://t.me/GlmBot')
            ->assertJsonPath('bots.whatsapp', 'https://wa.me/201000000000?text='.rawurlencode('مرحبا'))
            ->assertJsonPath('bots.telegram_channel', 'https://t.me/glm_news')
            ->assertJsonPath('bots.whatsapp_channel', null);
        $this->getJson('/api/v1/bootstrap')->assertOk()->assertJsonPath('config.bots.telegram', 'https://t.me/GlmBot');
        config(['services.telegram.token' => null]);
        $this->getJson('/api/v1/health')->assertJsonPath('bots.telegram', null);
    }

    public function test_the_channel_is_read_in_any_usual_form(): void
    {
        foreach (['glm_news', '@glm_news', 't.me/glm_news', 'https://t.me/glm_news', 'https://t.me/glm_news/12', ' https://telegram.me/s/glm_news '] as $form) {
            config(['services.telegram.channel' => $form]);
            $this->assertSame(['chat' => '@glm_news', 'url' => 'https://t.me/glm_news'], Messenger::telegramChannel(), $form);
        }
        // A private channel: posted to by its number, opened by its invite link.
        config(['services.telegram.channel' => '-1001234567890', 'services.telegram.channel_url' => 'https://t.me/+AbCdEf']);
        $this->assertSame(['chat' => '-1001234567890', 'url' => 'https://t.me/+AbCdEf'], Messenger::telegramChannel());
        // An invite link alone: people open it, the bot does not post.
        config(['services.telegram.channel' => 'https://t.me/+AbCdEf', 'services.telegram.channel_url' => null]);
        $this->assertSame(['chat' => null, 'url' => 'https://t.me/+AbCdEf'], Messenger::telegramChannel());
        Messenger::post('weekly', 'x');
        $this->assertSame([], $this->sent('api.telegram.org'));
    }

    public function test_unlinking_from_the_profile(): void
    {
        $this->linkTelegram($this->owner);
        $this->actingAs($this->owner)->deleteJson('/api/v1/messenger/telegram')->assertOk()->assertJsonPath('telegram.linked', false);
        $this->actingAs($this->owner)->putJson('/api/v1/messenger/whatsapp', ['muted' => true])->assertOk();
        // [Sprint 68] The live matches and the daily summary's hour, from the profile.
        $this->linkTelegram($this->owner);
        $this->actingAs($this->owner)->putJson('/api/v1/messenger/telegram', ['live' => false, 'daily_hour' => 8])->assertOk()
            ->assertJsonPath('telegram.live', false)->assertJsonPath('telegram.daily_hour', 8);
        $this->actingAs($this->owner)->putJson('/api/v1/messenger/telegram', ['daily_hour' => 24])->assertUnprocessable();
        $this->actingAs($this->owner)->putJson('/api/v1/messenger/telegram', ['daily_hour' => null])->assertOk()->assertJsonPath('telegram.daily_hour', null);
        $this->actingAs($this->owner)->deleteJson('/api/v1/messenger/signal')->assertNotFound();
    }
}
