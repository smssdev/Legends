<?php

namespace Tests;

use App\Data\Crests;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        // [UP2] The test client asks for English by default (Symfony's en-us); the game's default is Arabic, as the web
        // and the app send it.
        $this->withHeader('Accept-Language', 'ar');
        // [Sprint 58 B2] The crests a test writes (the data editor's) in a folder of its own, not beside the real ones.
        $dir = sys_get_temp_dir().'/legends-crests-'.getmypid();
        config(['game.crests.dir' => $dir, 'game.crests.manifest' => $dir.'/crests.json']);
        Crests::forget();
    }
}
