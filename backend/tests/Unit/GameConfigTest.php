<?php

namespace Tests\Unit;

use Tests\TestCase;

class GameConfigTest extends TestCase
{
    /**
     * The engine works on integers only (CLAUDE.md), so every number it can
     * read from config/game.php must be an integer.
     */
    public function test_engine_and_match_values_contain_no_floats(): void
    {
        $floats = [];

        $values = ['match' => config('game.match'), 'engine' => config('game.engine')];

        array_walk_recursive(
            $values,
            function ($value, $key) use (&$floats) {
                if (is_float($value)) {
                    $floats[] = $key;
                }
            }
        );

        $this->assertSame([], $floats);
    }
}
