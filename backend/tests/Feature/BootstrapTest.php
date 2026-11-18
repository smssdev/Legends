<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/** [Sprint 58 B1] GET /bootstrap: each part is its own route's, in one reply under 5 KB. */
class BootstrapTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_guest_gets_the_sites_settings_only(): void
    {
        $r = $this->getJson('/api/v1/bootstrap')->assertOk();
        $this->assertNull($r->json('user'));
        $this->assertNull($r->json('home'));
        $health = $this->getJson('/api/v1/health')->json();
        foreach (['support', 'adsense', 'analytics', 'broadcast', 'version', 'unity_build'] as $k) {
            $this->assertSame($health[$k], $r->json("config.$k"), $k);
        }
    }

    /** [Sprint 11 X1] The Unity web build the match screen loads, only as a safe path part; none: the cartoon plays. */
    public function test_the_unity_build_is_given_when_deployed_and_safe(): void
    {
        $this->assertNull($this->getJson('/api/v1/health')->json('unity_build'));
        config(['game.viewing.unity_build' => '2026.11.18']);
        $this->assertSame('2026.11.18', $this->getJson('/api/v1/health')->json('unity_build'));
        $this->assertSame('2026.11.18', $this->getJson('/api/v1/bootstrap')->json('config.unity_build'));
        foreach (['../etc', 'a/b', '<x>', str_repeat('a', 41)] as $bad) {
            config(['game.viewing.unity_build' => $bad]);
            $this->assertNull($this->getJson('/api/v1/health')->json('unity_build'), $bad);
        }
    }

    public function test_a_coach_gets_each_part_as_its_own_route_gives_it(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user);
        $r = $this->getJson('/api/v1/bootstrap')->assertOk();
        $this->assertSame($this->getJson('/api/v1/auth/me')->json('user'), $r->json('user'));
        $this->assertSame($this->getJson('/api/v1/wallet')->json(), $r->json('wallet'));
        $home = $this->getJson('/api/v1/home')->json();
        $this->assertSame(['coach' => $home['coach'], 'slots' => $home['slots']], $r->json('home'));
        $this->assertSame($this->getJson('/api/v1/messages/unread')->json('unread'), $r->json('unread'));
        $this->assertLessThan(5 * 1024, strlen($r->getContent()), 'the bootstrap stays small');
    }

    public function test_a_token_that_no_longer_works_is_told_to_sign_in_again(): void
    {
        $this->getJson('/api/v1/bootstrap', ['Authorization' => 'Bearer nope'])->assertUnauthorized();
    }
}
