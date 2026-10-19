<?php

namespace App\Data;

/**
 * Growth ceiling by age (docs/PLAN.md 2.8): young players have room to grow,
 * players over 30 barely any. A first rule, calibrated in Sprint 13.
 */
class Potential
{
    public static function for(int $overall, int $age): int
    {
        $room = match (true) {
            $age <= 19 => 14,
            $age <= 21 => 10,
            $age <= 23 => 7,
            $age <= 26 => 4,
            $age <= 29 => 2,
            default => 0,
        };

        return min(99, $overall + $room);
    }
}
