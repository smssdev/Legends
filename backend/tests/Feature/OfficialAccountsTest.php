<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\VerifyEmailNotice;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

/** [X11] The developers' fixed accounts: a configured Gmail, once confirmed, takes its reserved name and the admin panel. */
class OfficialAccountsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['game.account.official_emails' => ['Owner-Sizar' => 'hamza.dev@gmail.com', 'Owner-Sliman' => 'Soliman.Dev@gmail.com']]);
    }

    private function register(string $email, string $username): TestResponse
    {
        return $this->postJson('/api/v1/auth/register', ['name' => 'مطور', 'username' => $username, 'email' => $email,
            'password' => 'secret123', 'password_confirmation' => 'secret123', 'terms' => true, 'device_name' => 'Pixel']);
    }

    public function test_the_developers_gmail_takes_its_name_only_once_confirmed(): void
    {
        Notification::fake();
        // Signed up, not confirmed yet: an ordinary account.
        $this->register('soliman.dev@gmail.com', 'sliman')->assertCreated()
            ->assertJsonPath('user.username', 'sliman')->assertJsonPath('user.official', false);
        $user = User::where('email', 'soliman.dev@gmail.com')->firstOrFail();

        // The link in the email confirms it: the reserved name, the badge and the admin panel.
        $this->get(VerifyEmailNotice::url($user))->assertRedirect();
        $user->refresh();
        $this->assertSame(['owner-sliman', 'admin'], [$user->username, $user->role]);
        $this->assertTrue($user->toAccount()['official']);
    }

    public function test_a_confirmed_developer_signing_in_takes_it_and_others_never_do(): void
    {
        $hamza = User::factory()->create(['email' => 'hamza.dev@gmail.com', 'username' => 'hamza', 'password' => 'secret123']);
        $this->postJson('/api/v1/auth/token', ['email' => 'hamza.dev@gmail.com', 'password' => 'secret123', 'device_name' => 'Pixel'])->assertOk()
            ->assertJsonPath('user.username', 'owner-sizar')->assertJsonPath('user.official', true)->assertJsonPath('user.role', 'admin');

        // Someone else, confirmed, stays as they are.
        $other = User::factory()->create(['email' => 'fan@gmail.com', 'username' => 'fan', 'password' => 'secret123']);
        $this->postJson('/api/v1/auth/token', ['email' => 'fan@gmail.com', 'password' => 'secret123', 'device_name' => 'Pixel'])->assertOk()
            ->assertJsonPath('user.username', 'fan')->assertJsonPath('user.role', 'user');
        $this->assertSame('owner-sizar', $hamza->fresh()->username);
    }

    public function test_no_address_on_the_server_gives_nobody_the_names(): void
    {
        config(['game.account.official_emails' => ['Owner-Sizar' => null, 'Owner-Sliman' => '']]);
        User::factory()->create(['email' => 'x@gmail.com', 'username' => 'xuser', 'password' => 'secret123']);
        $this->postJson('/api/v1/auth/token', ['email' => 'x@gmail.com', 'password' => 'secret123', 'device_name' => 'P'])->assertOk()
            ->assertJsonPath('user.username', 'xuser');
    }
}
