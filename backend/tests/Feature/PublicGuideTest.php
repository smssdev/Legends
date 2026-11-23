<?php

namespace Tests\Feature;

use App\Assistant\Guide;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/** [X59] The game's guide is open to visitors, in both languages, every topic of the assistant but his own. */
class PublicGuideTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_visitor_reads_the_whole_guide_in_sections(): void
    {
        $ar = $this->getJson('/api/v1/guide')->assertOk()->assertJsonPath('sections.0.id', 'start')
            // [Sprint 59 F1] The fields the app reads through its generated model (openapi.yaml).
            ->assertJsonStructure(['sections' => ['*' => ['id', 'title', 'topics' => ['*' => ['id', 'q', 'a']]]]])->json('sections');
        $ids = collect($ar)->flatMap(fn ($s) => collect($s['topics'])->pluck('id'));
        $this->assertNotContains('about', $ids);
        $this->assertContains('tactics', collect($ar)->pluck('id'));
        $this->assertContains('training', $ids);
        $this->assertSame($ids->count(), $ids->unique()->count());
        foreach ($ar as $s) {
            foreach ($s['topics'] as $t) {
                $this->assertNotSame('', trim($t['a']), $t['id']);
            }
        }

        $en = $this->withHeader('Accept-Language', 'en')->getJson('/api/v1/guide')->assertOk()->json('sections');
        $this->assertSame('Getting started', $en[0]['title']);
        $this->assertSame($ids->all(), collect($en)->flatMap(fn ($s) => collect($s['topics'])->pluck('id'))->all());
    }

    /** [Sprint 75 W5, WEB-05] How many teams a tournament takes: the game's own limits, once each, in both languages. */
    public function test_the_tournament_answer_states_the_limits_the_game_checks(): void
    {
        $c = config('game.tournaments');
        foreach (['ar', 'en'] as $l) {
            $topic = collect(Guide::topics($l))->firstWhere('id', 'tournaments');
            $this->assertNotNull($topic);
            preg_match_all('/\d+/', $topic['a'], $numbers);
            $this->assertContains((string) $c['max_teams'], $numbers[0], $l);
            $this->assertContains((string) $c['knockout_max_teams'], $numbers[0], $l);
            // The template's 32 nations aside, the largest number is the game's own limit.
            $this->assertSame($c['max_teams'], max(array_map('intval', $numbers[0])), $l);
        }
    }

    /**
     * [Sprint 75 W3, WEB-03] The inactivity rule (game.inactivity) is in the privacy policy and the terms the visitor
     * reads, with the game's own numbers, in both languages (web/src/content/legal.ts).
     */
    public function test_the_legal_pages_state_the_inactivity_rule(): void
    {
        $legal = (string) file_get_contents(base_path('../web/src/content/legal.ts'));
        $days = config('game.inactivity.inactive_days');
        $warn = config('game.inactivity.warn_after_days');
        $this->assertStringContainsString("{$days} يوماً متتالية", $legal);
        $this->assertStringContainsString("{$warn} يوماً", $legal);
        $this->assertStringContainsString("{$days} days in a row", $legal);
        $this->assertStringContainsString("{$warn} days", $legal);
    }
}
