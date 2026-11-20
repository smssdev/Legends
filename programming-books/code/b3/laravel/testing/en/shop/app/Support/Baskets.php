<?php

namespace App\Support;

use Illuminate\Support\Carbon;

// a basket left alone for 30 minutes is released
class Baskets
{
    public static function isExpired(Carbon $lastTouched): bool
    {
        return $lastTouched->diffInMinutes(now()) >= 30;
    }
}
