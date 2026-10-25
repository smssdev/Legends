<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/** [X9, X10] The commentator (the sixth voice by default) and the simulator, kept with the account. */
class ViewingPreferencesTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_new_account_hears_the_sixth_voice_on_the_cartoon_simulator(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $this->getJson('/api/v1/auth/me')->assertOk()
            ->assertJsonPath('user.viewing', ['commentator' => 'voice-6', 'match_view' => 'cartoon', 'unity_ready' => false]);
    }

    public function test_the_coach_picks_another_voice_and_unity_alone(): void
    {
        $user = User::factory()->create(['name' => 'سليمان']);
        Sanctum::actingAs($user);
        $this->patchJson('/api/v1/auth/me', ['commentator' => 'voice-2'])->assertOk()->assertJsonPath('user.viewing.commentator', 'voice-2')
            ->assertJsonPath('user.name', 'سليمان');
        $this->patchJson('/api/v1/auth/me', ['match_view' => 'unity'])->assertOk()->assertJsonPath('user.viewing.match_view', 'unity');
        $this->assertSame(['voice-2', 'unity'], [$user->fresh()->commentator, $user->fresh()->match_view]);
    }

    public function test_unknown_choices_are_refused_in_arabic(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $this->patchJson('/api/v1/auth/me', ['commentator' => 'voice-9', 'match_view' => 'vr'])->assertStatus(422)
            ->assertJsonPath('errors.commentator.0', 'قيمة المعلق غير مسموحة.')
            ->assertJsonPath('errors.match_view.0', 'قيمة طريقة عرض المباراة غير مسموحة.');
        $this->patchJson('/api/v1/auth/me', [])->assertStatus(422);
    }
}
