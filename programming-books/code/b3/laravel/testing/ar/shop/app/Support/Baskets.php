<?php

namespace App\Support;

use Illuminate\Support\Carbon;

// السلة المتروكة 30 دقيقة تُحرَّر
class Baskets
{
    public static function isExpired(Carbon $lastTouched): bool
    {
        return $lastTouched->diffInMinutes(now()) >= 30;
    }
}
