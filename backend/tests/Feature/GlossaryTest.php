<?php

namespace Tests\Feature;

use Tests\TestCase;

/** [X19] The "?" texts: every term explained in Arabic, with the game's own numbers. */
class GlossaryTest extends TestCase
{
    public function test_every_term_has_an_arabic_explanation_from_the_config(): void
    {
        $terms = $this->getJson('/api/v1/data/glossary')->assertOk()->json('terms');
        foreach (['training', 'potential', 'stadium', 'specialists', 'scout', 'pool', 'quick_sale', 'listing', 'value', 'fitness'] as $k) {
            $this->assertMatchesRegularExpression('/\p{Arabic}/u', $terms[$k] ?? '', $k);
        }
        $this->assertStringContainsString('15 ساعة', $terms['scout']);
        $this->assertStringContainsString('5 خيارات', $terms['scout']);
    }
}
