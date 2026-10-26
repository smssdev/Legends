<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        // [UP2] The test client asks for English by default (Symfony's en-us); the game's default is Arabic, as the web
        // and the app send it.
        $this->withHeader('Accept-Language', 'ar');
    }
}
