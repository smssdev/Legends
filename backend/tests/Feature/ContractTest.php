<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\Support\OpenApiContract;
use Tests\TestCase;

/**
 * [Sprint 66 T9] The real answers against the contract: every GET the contract lists that a coach (or the admin, for
 * /admin) can open without more than a league, run on a started league, and each answer checked against what
 * docs/api/openapi.yaml says it is. The web's types and the app's models are made from the contract, so an answer
 * that drifts from it breaks a screen: this fails first.
 */
class ContractTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    /** Asked with a query the test does not have (a player, a price): their own Feature tests cover them. */
    private const NEEDS_QUERY = ['/auth/username', '/leagues/{league}/market/buy-quote', '/leagues/{league}/market/quote', '/app/android.apk'];

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_every_get_answers_as_the_contract_says(): void
    {
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create(['role' => 'admin']);
        $league = $this->makeLeague($owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1, 'starts_at' => '2026-10-22T10:00:00Z']);
        $this->actingAs($owner)->postJson("/api/v1/leagues/{$league['id']}/start")->assertOk();
        // From the site (the admin's routes take the session).
        $this->withHeader('Referer', config('app.url'));

        $checked = 0;
        $problems = [];
        foreach (OpenApiContract::paths('get') as $path) {
            if (in_array($path, self::NEEDS_QUERY, true)) {
                continue;
            }
            $url = str_replace('{league}', (string) $league['id'], $path);
            if (str_contains($url, '{')) {
                continue;   // another id (a match, a group, a player): their own tests
            }
            $response = $this->actingAs($owner)->getJson('/api/v1'.$url);
            $status = $response->status();
            if ($status >= 300 || ! str_contains((string) $response->headers->get('Content-Type'), 'json')) {
                continue;   // not this league's (a tournament's page), or a file
            }
            $found = OpenApiContract::check('get', $path, $status, $response->json());
            if ($found === null) {
                continue;
            }
            $checked++;
            array_push($problems, ...$found);
        }

        $this->assertGreaterThan(50, $checked, 'most of the contract was reached');
        $this->assertSame([], $problems, "The answers differ from docs/api/openapi.yaml:\n".implode("\n", $problems));
    }
}
