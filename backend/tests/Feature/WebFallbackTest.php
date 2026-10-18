<?php

namespace Tests\Feature;

use Tests\TestCase;

class WebFallbackTest extends TestCase
{
    public function test_web_paths_fall_back_to_the_app_and_unknown_api_paths_stay_404(): void
    {
        $this->get('/sim/abc/report')->assertOk();
        $this->getJson('/api/v1/nothing-here')->assertNotFound();
    }
}
