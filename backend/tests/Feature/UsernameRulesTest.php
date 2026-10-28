<?php

namespace Tests\Feature;

use App\Auth\Username;
use App\Http\Middleware\AdminOnly;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Testing\TestResponse;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/** [X11] Letters and digits, the staff's words refused, suggestions, and the developers' official names. */
class UsernameRulesTest extends TestCase
{
    use RefreshDatabase;

    private function register(string $username, string $email): TestResponse
    {
        return $this->postJson('/api/v1/auth/register', ['name' => 'مدرب', 'username' => $username, 'email' => $email,
            'password' => 'secret123', 'password_confirmation' => 'secret123', 'terms' => true, 'device_name' => 'Pixel']);
    }

    public function test_digits_are_allowed_and_the_staff_words_are_not(): void
    {
        $this->register('Coach10', 'a@example.com')->assertCreated()->assertJsonPath('user.username', 'coach10')->assertJsonPath('user.official', false);
        foreach (['TheOwner', 'admin7', 'SupportMe', 'mod', 'mod12', 'legendsfan'] as $i => $bad) {
            $this->register($bad, "b{$i}@example.com")->assertStatus(422)
                ->assertJsonPath('errors.username.0', 'اسم المستخدم فيه كلمة محجوزة لفريق اللعبة، اختر غيره.');
        }
        // A short word inside a longer name is fine.
        $this->register('modric', 'c@example.com')->assertCreated();
    }

    public function test_the_check_answers_as_it_is_typed_with_three_free_suggestions(): void
    {
        User::factory()->create(['username' => 'hamza']);
        User::factory()->create(['username' => 'hamzafc']);
        $this->getJson('/api/v1/auth/username?u=Hamza')->assertOk()
            ->assertJsonPath('available', false)->assertJsonPath('reason', 'اسم المستخدم مأخوذ، اختر غيره.')
            ->assertJsonPath('suggestions', ['hamza10', 'coachhamza', 'hamza7']);
        $this->getJson('/api/v1/auth/username?u=Hamza2')->assertOk()->assertJsonPath('available', true)->assertJsonPath('suggestions', []);
        $this->getJson('/api/v1/auth/username?u=AdminHamza')->assertOk()->assertJsonPath('available', false)
            ->assertJsonPath('suggestions.0', 'hamza10');
    }

    public function test_a_google_account_from_an_admin_email_still_gets_a_name(): void
    {
        // The part of the email before @, as User::booted gives it.
        $this->assertSame('coach', Username::free('admin'));
        $this->assertSame(['coachfc', 'coach10', 'thecoach'], Username::suggestions('Admin'));
        $this->assertSame('hamza', Username::free('owner.hamza'));
    }

    public function test_only_the_admin_gives_the_official_names_and_only_they_announce(): void
    {
        $admin = User::factory()->create(['role' => 'admin', 'name' => 'سليمان']);
        $coach = User::factory()->create();
        $this->withoutMiddleware(AdminOnly::class);
        Sanctum::actingAs($admin);
        // Not yet official: no announcement.
        $this->postJson('/api/v1/admin/announcements', ['title' => 'تحديث', 'body' => 'نص'])->assertStatus(403);
        $this->postJson("/api/v1/admin/users/{$admin->id}/official", ['name' => 'Owner-Sliman'])->assertOk()
            ->assertJsonPath('user.username', 'owner-sliman')->assertJsonPath('user.official', true);
        $this->postJson("/api/v1/admin/users/{$coach->id}/official", ['name' => 'Owner-Sliman'])->assertStatus(409);
        $this->postJson("/api/v1/admin/users/{$coach->id}/official", ['name' => 'Owner-Ali'])->assertStatus(422);

        Sanctum::actingAs($admin->fresh());
        $this->postJson('/api/v1/admin/announcements', ['title' => 'تحديث جديد', 'body' => 'وصل المعلق الجديد.'])->assertCreated()->assertJsonPath('sent', 2);
        Sanctum::actingAs($coach);
        $this->getJson('/api/v1/messages')->assertOk()
            ->assertJsonPath('messages.0.title', 'تحديث جديد')
            ->assertJsonPath('messages.0.sender', ['name' => 'سليمان', 'username' => 'Owner-Sliman', 'official' => true]);
        $this->assertSame(2, DB::table('messages')->where('type', 'announcement')->count());
    }
}
