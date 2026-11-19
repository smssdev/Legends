<?php

namespace App\Http\Resources;

final class Money
{
    /** @return array{amount: int, currency: string} */
    public static function of(int $amount): array
    {
        return ['amount' => $amount, 'currency' => config('shop.currency')];
    }
}
