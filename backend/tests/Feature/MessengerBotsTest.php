<?php

namespace Tests\Feature;

use App\Messenger\Messenger;
use App\Messenger\WhatsApp;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/**
 * [Sprint 70] The bots grown: WhatsApp shows every button Telegram does (a list for more than three, a link button,
 * a long text before its buttons), marks his message read, reminds a coach with a match before its free window shuts;
 * Telegram types while it answers and greets a group it joins; messenger:setup says what is still missing.
 */
class MessengerBotsTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private int $update = 1;

    /** Meta answers that the free window is shut. */
    private bool $shut = false;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        config(['services.telegram.token' => '123:tg-token', 'services.telegram.secret' => 'tg-secret', 'services.telegram.username' => 'GlmBot',
            'services.whatsapp.token' => 'wa-token', 'services.whatsapp.phone_id' => '555', 'services.whatsapp.app_secret' => 'wa-app-secret',
            'services.whatsapp.verify' => 'wa-verify', 'services.whatsapp.number' => '201031916497', 'services.whatsapp.business_id' => '999',
            'services.gemini.key' => null, 'app.frontend_url' => 'https://game.test', 'app.url' => 'https://game.test']);
        Http::fake(['api.telegram.org/*' => Http::response(['ok' => true, 'result' => ['username' => 'GlmBot', 'supports_inline_queries' => false, 'can_read_all_group_messages' => false]]),
            'graph.facebook.com/*/messages' => fn () => $this->shut ? Http::response(['error' => ['code' => 131047, 'message' => 'Re-engagement message']], 400)
                : Http::response(['messages' => [['id' => 'x']]]),
            'graph.facebook.com/*' => Http::response(['display_phone_number' => '+20 10 31916497', 'verified_name' => 'Game Legend Manager', 'quality_rating' => 'GREEN', 'success' => true])]);
        $this->owner = User::factory()->create(['name' => 'Sliman', 'locale' => 'ar']);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function whatsapp(array $message, string $from = '201000000001')
    {
        $body = json_encode(['entry' => [['changes' => [['value' => ['messages' => [['from' => $from, 'id' => 'wamid.'.$this->update++] + $message]]]]]]]);

        return $this->call('POST', '/api/v1/messenger/whatsapp', [], [], [], ['CONTENT_TYPE' => 'application/json',
            'HTTP_X_HUB_SIGNATURE_256' => 'sha256='.hash_hmac('sha256', $body, 'wa-app-secret')], $body)->assertOk();
    }

    private function say(string $text, string $from = '201000000001')
    {
        return $this->whatsapp(['type' => 'text', 'text' => ['body' => $text]], $from);
    }

    /** What the bot sent on WhatsApp (not the «read»), each the whole message. */
    private function sent(): array
    {
        return Http::recorded()->filter(fn ($r) => str_ends_with($r[0]->url(), '/messages') && ! isset($r[0]['status']))->map(fn ($r) => $r[0]->data())->values()->all();
    }

    private function linkWhatsapp(): void
    {
        $this->say('ربط '.Messenger::code($this->owner->id)['code']);
    }

    public function test_whatsapp_shows_the_whole_menu_as_one_list_and_a_tapped_row_is_its_command(): void
    {
        $this->makeLeague($this->owner);
        $this->linkWhatsapp();
        $this->say('القائمة');
        $menu = last($this->sent());
        $this->assertSame('list', $menu['interactive']['type']);
        $rows = $menu['interactive']['action']['sections'][0]['rows'];
        $this->assertCount(10, $rows);
        $this->assertContains('training', array_column($rows, 'id'));
        $this->assertSame('اختر', $menu['interactive']['action']['button']);
        foreach ($rows as $r) {
            $this->assertLessThanOrEqual(24, mb_strlen($r['title']));
        }

        // A tapped row comes back as list_reply, and is answered as its command.
        $this->whatsapp(['type' => 'interactive', 'interactive' => ['type' => 'list_reply', 'list_reply' => ['id' => 'balance', 'title' => 'رصيدي']]]);
        $this->assertStringContainsString('الكوينز', last($this->sent())['text']['body'] ?? last($this->sent())['interactive']['body']['text']);
    }

    public function test_his_message_is_marked_read_with_typing(): void
    {
        $this->say('مرحبا');
        $read = Http::recorded()->first(fn ($r) => isset($r[0]['status']));
        $this->assertSame('read', $read[0]['status']);
        $this->assertSame('wamid.1', $read[0]['message_id']);
        $this->assertSame('text', $read[0]['typing_indicator']['type']);
    }

    public function test_a_long_text_goes_before_its_buttons_and_a_lone_link_is_a_link_button(): void
    {
        $long = str_repeat('سطر طويل من الشرح. ', 80);
        WhatsApp::send('201000000001', $long, [['نعم', 'do:x'], ['لا', 'cancel']]);
        [$text, $buttons] = array_slice($this->sent(), -2);
        $this->assertSame('text', $text['type']);
        $this->assertSame('button', $buttons['interactive']['type']);
        $this->assertSame('اختر:', $buttons['interactive']['body']['text']);

        // Not linked: the menu has one button, to his profile.
        $this->say('مرحبا', '201000000009');
        $cta = last($this->sent());
        $this->assertSame('cta_url', $cta['interactive']['type']);
        $this->assertSame('https://game.test/profile', $cta['interactive']['action']['parameters']['url']);
        $this->assertSame('افتح ملفي', $cta['interactive']['action']['parameters']['display_text']);
    }

    public function test_more_than_ten_choices_keep_the_first_ten_and_long_labels_go_in_the_description(): void
    {
        $choices = array_map(fn ($i) => ["لاعب باسم طويل جداً جداً رقم {$i}", "pick:{$i}"], range(1, 12));
        $list = WhatsApp::interactive('اختر لاعباً', $choices, null, true);
        $rows = $list['action']['sections'][0]['rows'];
        $this->assertCount(10, $rows);
        $this->assertSame(24, mb_strlen($rows[0]['title']));
        $this->assertSame('لاعب باسم طويل جداً جداً رقم 1', $rows[0]['description']);
    }

    public function test_meta_saying_the_window_is_shut_closes_it_on_the_profile(): void
    {
        $this->linkWhatsapp();
        $this->assertNotNull(DB::table('messenger_links')->where('platform', 'whatsapp')->value('last_inbound_at'));
        $this->shut = true;
        Messenger::toUser($this->owner->id, fn () => 'خبر');
        $this->assertNull(DB::table('messenger_links')->where('platform', 'whatsapp')->value('last_inbound_at'));
    }

    public function test_a_coach_with_a_match_tomorrow_is_reminded_once_before_his_window_shuts(): void
    {
        $league = $this->makeLeague($this->owner);
        $this->linkWhatsapp();
        $club = DB::table('clubs')->where('league_id', $league['id'])->where('user_id', $this->owner->id)->value('id');
        $this->assertNotNull($club);
        // His next match: the league's first fixture of his club, a day and a half from now.
        DB::table('fixtures')->where(fn ($q) => $q->where('home_id', $club)->orWhere('away_id', $club))->update(['scheduled_at' => Carbon::parse('2026-10-23 20:00:00')]);

        $this->artisan('messenger:whatsapp-window')->assertSuccessful();
        $this->assertSame([], array_filter($this->sent(), fn ($m) => str_contains(json_encode($m, JSON_UNESCAPED_UNICODE), 'استمر')));

        // 21½ hours after his message: within the last two hours of the window.
        Carbon::setTestNow('2026-10-23 07:30:00');
        $this->artisan('messenger:whatsapp-window')->assertSuccessful();
        $this->artisan('messenger:whatsapp-window')->assertSuccessful();
        $warned = array_values(array_filter($this->sent(), fn ($m) => str_contains(json_encode($m, JSON_UNESCAPED_UNICODE), 'استمر')));
        $this->assertCount(1, $warned);
        $this->assertSame('keep', $warned[0]['interactive']['action']['buttons'][0]['reply']['id']);

        // «استمر» opens the window again.
        $this->whatsapp(['type' => 'interactive', 'interactive' => ['type' => 'button_reply', 'button_reply' => ['id' => 'keep', 'title' => 'استمر']]]);
        $this->assertStringContainsString('23 ساعة', json_encode(last($this->sent()), JSON_UNESCAPED_UNICODE));
        $this->assertTrue(Carbon::parse(DB::table('messenger_links')->where('platform', 'whatsapp')->value('last_inbound_at'))->eq(Carbon::now()));

        // A muted bot is never reminded.
        DB::table('messenger_links')->update(['muted' => true, 'last_inbound_at' => Carbon::now()->subMinutes(21 * 60 + 30)]);
        $before = count($this->sent());
        $this->artisan('messenger:whatsapp-window')->assertSuccessful();
        $this->assertCount($before, $this->sent());
    }

    public function test_telegram_types_while_answering_and_greets_a_group_it_joins(): void
    {
        $this->withHeader('X-Telegram-Bot-Api-Secret-Token', 'tg-secret')->postJson('/api/v1/messenger/telegram', ['update_id' => $this->update++,
            'message' => ['chat' => ['id' => 777, 'type' => 'private'], 'from' => ['id' => 777], 'text' => 'مرحبا']])->assertOk();
        $this->assertTrue(Http::recorded()->contains(fn ($r) => str_ends_with($r[0]->url(), '/sendChatAction') && $r[0]['action'] === 'typing'));
        // Not linked: a button to his profile.
        $hello = Http::recorded()->last(fn ($r) => str_ends_with($r[0]->url(), '/sendMessage'))[0];
        $this->assertSame('https://game.test/profile', $hello['reply_markup']['inline_keyboard'][0][0]['url']);

        $join = fn (string $old, string $new) => $this->withHeader('X-Telegram-Bot-Api-Secret-Token', 'tg-secret')->postJson('/api/v1/messenger/telegram', [
            'update_id' => $this->update++, 'my_chat_member' => ['chat' => ['id' => -100500, 'type' => 'supergroup'],
                'old_chat_member' => ['status' => $old], 'new_chat_member' => ['status' => $new]]])->assertOk();
        $join('left', 'member');
        $greet = Http::recorded()->last(fn ($r) => str_ends_with($r[0]->url(), '/sendMessage'))[0];
        $this->assertSame('-100500', (string) $greet['chat_id']);
        $this->assertStringContainsString('/league', $greet['text']);
        $this->assertStringContainsString('@GlmBot', $greet['text']);
        // Made an admin later: no second greeting.
        $n = Http::recorded()->filter(fn ($r) => str_ends_with($r[0]->url(), '/sendMessage'))->count();
        $join('member', 'administrator');
        $this->assertSame($n, Http::recorded()->filter(fn ($r) => str_ends_with($r[0]->url(), '/sendMessage'))->count());
    }

    public function test_setup_sets_both_bots_and_says_what_is_missing(): void
    {
        $this->artisan('messenger:setup')
            ->expectsOutputToContain('Telegram: the webhook is https://game.test/api/v1/messenger/telegram.')
            ->expectsOutputToContain('commands menus are set')
            ->expectsOutputToContain('description is set')
            ->expectsOutputToContain('/setinline')
            ->expectsOutputToContain('/setprivacy')
            ->expectsOutputToContain('the number is +20 10 31916497')
            ->expectsOutputToContain('business profile is set')
            ->expectsOutputToContain('subscribed')
            ->assertSuccessful();
        $hook = Http::recorded()->first(fn ($r) => str_ends_with($r[0]->url(), '/setWebhook'))[0];
        $this->assertContains('my_chat_member', $hook['allowed_updates']);
        $this->assertTrue(Http::recorded()->contains(fn ($r) => str_ends_with($r[0]->url(), '/setMyCommands') && ($r[0]['scope']['type'] ?? null) === 'all_group_chats'));
        $this->assertTrue(Http::recorded()->contains(fn ($r) => str_ends_with($r[0]->url(), '/999/subscribed_apps')));

        config(['services.whatsapp.token' => null, 'services.whatsapp.app_secret' => null]);
        $this->artisan('messenger:setup')->expectsOutputToContain('WhatsApp: off. Still to set with legends-set: WHATSAPP_TOKEN, WHATSAPP_APP_SECRET.')->assertSuccessful();
    }
}
