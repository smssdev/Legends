<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/** [X58] The game's guide is open to visitors, in both languages, every topic of the assistant but his own. */
class PublicGuideTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_visitor_reads_the_whole_guide_in_sections(): void
    {
        $ar = $this->getJson('/api/v1/guide')->assertOk()->assertJsonPath('sections.0.id', 'start')->json('sections');
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
}
