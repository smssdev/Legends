<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    protected $seed = true;

    private function signIn(string $email, string $password): array
    {
        $token = $this->postJson('/api/auth/login', compact('email', 'password'))
            ->assertOk()
            ->json('token');

        return ['Authorization' => "Bearer $token"];
    }

    public function test_it_registers_signs_in_and_reads_me(): void
    {
        $this->postJson('/api/auth/register', [
            'email' => 'test@example.com',
            'name' => 'Test',
            'password' => 'a long test password',
        ])->assertCreated();
        $as = $this->signIn('test@example.com', 'a long test password');
        $this->getJson('/api/me', $as)->assertJsonPath('email', 'test@example.com');
    }

    public function test_it_refuses_me_without_a_token(): void
    {
        $this->getJson('/api/me')->assertUnauthorized();
    }

    public function test_it_refuses_the_admin_list_to_a_customer(): void
    {
        $omar = $this->signIn('omar@example.com', 'omar-password-2026');
        $this->getJson('/api/admin/users', $omar)->assertForbidden();
    }

    public function test_it_hides_other_customers_orders(): void
    {
        $omar = $this->signIn('omar@example.com', 'omar-password-2026');
        $this->getJson('/api/orders/1', $omar)->assertNotFound();
    }

    public function test_it_rejects_a_token_after_sign_out(): void
    {
        $sara = $this->signIn('sara@example.com', 'sara-password-2026');
        $this->postJson('/api/auth/logout', [], $sara)->assertNoContent();
        $this->app['auth']->forgetGuards();
        $this->getJson('/api/me', $sara)->assertUnauthorized();
    }
}
