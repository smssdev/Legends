<?php

namespace Tests\Feature;

use App\League\Tactics;
use App\Messages\Inbox;
use App\Messages\MessageText;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/** [UP2] Arabic and English: the server answers in the language asked for, and the coach's choice is kept. */
class LocaleTest extends TestCase
{
    use RefreshDatabase;

    public function test_errors_come_in_arabic_by_default_and_in_english_when_asked(): void
    {
        $this->getJson('/api/v1/home')->assertStatus(401)->assertJsonPath('message', 'سجّل الدخول أولاً.');
        $this->withHeader('Accept-Language', 'en-US,en;q=0.9')->getJson('/api/v1/home')->assertStatus(401)->assertJsonPath('message', 'Sign in first.');
        // A language we do not have falls back to Arabic.
        $this->withHeader('Accept-Language', 'fr')->getJson('/api/v1/home')->assertStatus(401)->assertJsonPath('message', 'سجّل الدخول أولاً.');
    }

    public function test_the_games_own_messages_have_their_english(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user)->withHeader('Accept-Language', 'en')->postJson('/api/v1/leagues/join', ['code' => 'NOPE99'])
            ->assertStatus(404)->assertJsonPath('message', 'There is no league with this code.');
        $this->actingAs($user)->withHeader('Accept-Language', 'ar')->postJson('/api/v1/leagues/join', ['code' => 'NOPE99'])
            ->assertStatus(404)->assertJsonPath('message', 'لا يوجد دوري بهذا الكود.');
    }

    /** [Sprint 75 W2, WEB-02] The guide is public for ten minutes: a browser must keep one copy per language. */
    public function test_the_guide_varies_with_the_language(): void
    {
        $ar = $this->getJson('/api/v1/guide')->assertOk();
        $this->assertStringContainsString('Accept-Language', (string) $ar->headers->get('Vary'));
        $this->assertSame('البداية والحساب', $ar->json('sections.0.title'));
        $en = $this->withHeader('Accept-Language', 'en')->getJson('/api/v1/guide')->assertOk();
        $this->assertStringContainsString('Accept-Language', (string) $en->headers->get('Vary'));
        $this->assertSame('Getting started', $en->json('sections.0.title'));
        foreach ($en->json('sections') as $section) {
            foreach ($section['topics'] as $topic) {
                $this->assertDoesNotMatchRegularExpression('/\p{Arabic}/u', $topic['q'].$topic['a'], $topic['id']);
            }
        }
    }

    /** [Sprint 75 W12, WEB-12] The sign-in takes the email or the username, and its empty field says so. */
    public function test_an_empty_sign_in_asks_for_the_email_or_the_username(): void
    {
        $web = ['Origin' => 'http://localhost:5173', 'Referer' => 'http://localhost:5173/'];
        $this->withHeaders($web)->postJson('/api/v1/auth/login', ['email' => '', 'password' => ''])->assertStatus(422)
            ->assertJsonPath('errors.email.0', 'اكتب بريدك أو اسم المستخدم.');
        $this->withHeaders($web + ['Accept-Language' => 'en'])->postJson('/api/v1/auth/login', ['email' => '', 'password' => ''])->assertStatus(422)
            ->assertJsonPath('errors.email.0', 'Enter your email or username.');
        $this->withHeader('Accept-Language', 'ar')->postJson('/api/v1/auth/token', ['email' => '', 'password' => 'x', 'device_name' => 'phone'])->assertStatus(422)
            ->assertJsonPath('errors.email.0', 'اكتب بريدك أو اسم المستخدم.');
    }

    public function test_every_english_message_is_a_message_of_the_game(): void
    {
        $en = json_decode(file_get_contents(lang_path('en.json')), true);
        $this->assertNotEmpty($en);
        foreach ($en as $ar => $english) {
            $this->assertMatchesRegularExpression('/\p{Arabic}/u', $ar);
            $this->assertDoesNotMatchRegularExpression('/\p{Arabic}/u', $english);
        }
    }

    public function test_the_coach_keeps_a_language(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user)->getJson('/api/v1/auth/me')->assertJsonPath('user.locale', null);
        $this->actingAs($user)->patchJson('/api/v1/auth/me', ['locale' => 'en'])->assertOk()->assertJsonPath('user.locale', 'en');
        $this->assertSame('en', $user->fresh()->locale);
        $this->actingAs($user)->patchJson('/api/v1/auth/me', ['locale' => 'fr'])->assertStatus(422);
    }

    public function test_the_help_texts_have_the_same_terms_in_english(): void
    {
        $ar = $this->getJson('/api/v1/data/glossary')->assertOk()->json('terms');
        $en = $this->withHeader('Accept-Language', 'en')->getJson('/api/v1/data/glossary')->assertOk()->json('terms');
        $this->assertSame(array_keys($ar), array_keys($en));
        foreach ($en as $text) {
            $this->assertDoesNotMatchRegularExpression('/\p{Arabic}/u', $text);
        }
        $this->assertSame(array_keys(Tactics::HELP), array_keys(Tactics::HELP_EN));
    }

    public function test_every_message_type_has_its_english(): void
    {
        $p = ['league' => 'L', 'league_id' => 1, 'opponent' => 'X', 'club' => 'C', 'player' => 'P', 'overall' => 80, 'section' => 'seats', 'part' => 1, 'stage' => 1,
            'season' => 1, 'place' => 1, 'from' => 'A', 'to' => 'B', 'in' => ['P'], 'out' => [], 'money' => 0, 'players' => [], 'type' => 'doctor', 'home' => 'H', 'away' => 'W'];
        foreach (MessageText::TYPES as $type) {
            $ar = MessageText::render($type, $p, 'ar');
            $en = MessageText::render($type, $p, 'en');
            $this->assertSame(array_keys($ar), array_keys($en), $type);
            if ($type !== 'announcement') {
                $this->assertDoesNotMatchRegularExpression('/\p{Arabic}/u', $en['title'].$en['body'], $type);
            }
        }
    }

    public function test_a_message_reaches_its_recipient_in_their_language(): void
    {
        $user = User::factory()->create(['locale' => 'en']);
        Inbox::send($user->id, 'join_rejected', ['league' => 'Friends']);
        $this->actingAs($user)->withHeader('Accept-Language', 'en')->getJson('/api/v1/messages')->assertOk()
            ->assertJsonPath('messages.0.title', 'Your request was not approved');
    }

    public function test_every_tactics_tip_has_its_english(): void
    {
        app()->setLocale('en');
        foreach (['counter', 'long', 'passing', 'wings', 'shots'] as $plan) {
            foreach ([[90, 2], [90, 3], [50, 3], [10, 0]] as [$pressing, $tackling]) {
                foreach (['strict', 'medium'] as $referee) {
                    $t = ['plan' => $plan, 'pressing' => $pressing, 'tackling' => $tackling, 'tempo' => 80, 'style' => $pressing > 50 ? 80 : 10,
                        'trap' => 1, 'marking' => 'man', 'def' => 'fullbacks'];
                    foreach (Tactics::tips($t, $referee) as $tip) {
                        $this->assertDoesNotMatchRegularExpression('/\p{Arabic}/u', $tip);
                    }
                }
            }
        }
    }

    public function test_every_english_sentence_keeps_the_numbers_of_its_arabic(): void
    {
        $shape = function (string $s): array {
            preg_match_all('/%%|%[ds]/', $s, $m);

            return $m[0];
        };
        foreach (json_decode(file_get_contents(lang_path('en.json')), true) as $ar => $en) {
            $this->assertSame($shape($ar), $shape($en), $ar);
        }
    }
}
