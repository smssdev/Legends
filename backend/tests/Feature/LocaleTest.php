<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/** [UP2] Arabic and English: the server answers in the language asked for, and the coach's choice is kept. */
class LocaleTest extends TestCase
{
    use RefreshDatabase;

    public function test_errors_come_in_arabic_by_default_and_in_english_when_asked(): void
    {
        $this->getJson('/api/v1/auth/me')->assertStatus(401)->assertJsonPath('message', 'سجّل الدخول أولاً.');
        $this->withHeader('Accept-Language', 'en-US,en;q=0.9')->getJson('/api/v1/auth/me')->assertStatus(401)->assertJsonPath('message', 'Sign in first.');
        // A language we do not have falls back to Arabic.
        $this->withHeader('Accept-Language', 'fr')->getJson('/api/v1/auth/me')->assertStatus(401)->assertJsonPath('message', 'سجّل الدخول أولاً.');
    }

    public function test_the_games_own_messages_have_their_english(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user)->withHeader('Accept-Language', 'en')->postJson('/api/v1/leagues/join', ['code' => 'NOPE99'])
            ->assertStatus(404)->assertJsonPath('message', 'There is no league with this code.');
        $this->actingAs($user)->withHeader('Accept-Language', 'ar')->postJson('/api/v1/leagues/join', ['code' => 'NOPE99'])
            ->assertStatus(404)->assertJsonPath('message', 'لا يوجد دوري بهذا الكود.');
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
}
