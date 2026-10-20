<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/** The shared real data: league templates, squads with values, badges, and the summary [Sprint 11]. */
class DataApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->artisan('data:import', ['--data-version' => '2026', '--path' => base_path('tests/Fixtures/ea-fc26')])->assertSuccessful();
    }

    public function test_templates_list_each_league_with_its_clubs_strongest_first(): void
    {
        $res = $this->getJson('/api/v1/data/templates')->assertOk()->assertJsonPath('data_version', '2026')->json('templates');
        $this->assertNotEmpty($res);
        $tops = array_column($res, 'top_strength_cp');
        $sorted = $tops;
        rsort($sorted);
        $this->assertSame($sorted, $tops);
        $this->getJson('/api/v1/data/clubs?league='.urlencode($res[0]['name']))->assertOk()->assertJsonCount($res[0]['clubs'], 'clubs');
        $this->getJson('/api/v1/data/clubs?league=Nowhere')->assertNotFound()->assertJsonPath('message', 'لا يوجد دوري بهذا الاسم.');
    }

    public function test_a_club_shows_its_squad_with_potential_and_value(): void
    {
        $id = $this->getJson('/api/v1/data/templates')->json('templates.0.name');
        $club = $this->getJson('/api/v1/data/clubs?league='.urlencode($id))->json('clubs.0');
        $squad = $this->getJson("/api/v1/data/clubs/{$club['id']}")->assertOk()
            ->assertJsonPath('id', $club['id'])->assertJsonStructure(['crest_url', 'squad_value', 'players' => [['name', 'position', 'age', 'overall', 'potential', 'value', 'attributes']]])->json();
        foreach ($squad['players'] as $p) {
            $this->assertGreaterThanOrEqual($p['overall'], $p['potential']);
            $this->assertGreaterThan(0, $p['value']);
        }
        $this->assertSame(array_sum(array_column($squad['players'], 'value')), $squad['squad_value']);
        $this->assertSame('gk', $squad['players'][0]['line']);
    }

    public function test_the_badge_is_svg_the_same_every_time_and_cached(): void
    {
        $club = $this->getJson('/api/v1/data/clubs?league='.urlencode($this->getJson('/api/v1/data/templates')->json('templates.0.name')))->json('clubs.0');
        $first = $this->get("/api/v1/data/clubs/{$club['id']}/crest.svg")->assertOk()->assertHeader('Content-Type', 'image/svg+xml');
        $svg = $first->getContent();
        $this->assertStringStartsWith('<svg', $svg);
        $this->assertStringContainsString('>'.$club['code'].'</text>', $svg);
        $this->assertNotFalse(simplexml_load_string($svg));
        $this->assertSame($svg, $this->get("/api/v1/data/clubs/{$club['id']}/crest.svg")->getContent());
        $this->get("/api/v1/data/clubs/{$club['id']}/crest.svg", ['If-None-Match' => $first->headers->get('ETag')])->assertStatus(304);
    }

    public function test_the_summary_lists_the_strongest_clubs(): void
    {
        $league = $this->getJson('/api/v1/data/templates')->json('templates.0.name');
        $this->artisan('data:summary', ['--league' => $league, '--top' => 3])->assertSuccessful()->expectsOutputToContain('أقوى');
        $this->artisan('data:summary', ['--league' => 'Nowhere'])->assertFailed();
    }

    public function test_data_value_reworks_values_from_the_config(): void
    {
        config(['game.valuation.line_bp.att' => 20000]);
        $this->artisan('data:value')->assertSuccessful();
        $club = $this->getJson('/api/v1/data/clubs?league='.urlencode($this->getJson('/api/v1/data/templates')->json('templates.0.name')))->json('clubs.0');
        $players = collect($this->getJson("/api/v1/data/clubs/{$club['id']}")->json('players'));
        $att = $players->firstWhere('line', 'att');
        $mid = $players->where('line', 'mid')->firstWhere('overall', $att['overall']);
        if ($mid && $mid['age'] === $att['age']) {
            $this->assertGreaterThan($mid['value'], $att['value']);
        }
        $this->assertTrue($players->every(fn ($p) => $p['value'] > 0));
    }
}
