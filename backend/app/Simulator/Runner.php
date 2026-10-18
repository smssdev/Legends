<?php

namespace App\Simulator;

use App\Engine\MatchEngine;
use App\Engine\SeededRandom;

/** Advances an engine state tick by tick with the per-tick random stream. */
class Runner
{
    public static function tick(array $state, array $actions = []): array
    {
        return MatchEngine::simulateTick($state, $actions, SeededRandom::forTick($state['seed'], $state['tick'] + 1));
    }

    /** @return array{0: array, 1: list<array>} final state and every tick output */
    public static function toEnd(array $state, int $limit = 200): array
    {
        $ticks = [];
        while (! $state['finished'] && count($ticks) < $limit) {
            $state = self::tick($state);
            $ticks[] = $state['out'];
        }

        return [$state, $ticks];
    }
}
