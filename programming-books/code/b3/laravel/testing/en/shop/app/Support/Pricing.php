<?php

namespace App\Support;

use InvalidArgumentException;

// pure: the same input always gives the same output, and nothing else happens
class Pricing
{
    private const CODES = ['SAVE10' => ['percent' => 10], 'FIXED50' => ['amount' => 5000]];

    /** @param list<array{price: int, quantity: int}> $lines */
    public static function total(array $lines, ?string $code = null): array
    {
        $subtotal = array_sum(array_map(fn ($l) => $l['price'] * $l['quantity'], $lines));
        $discount = 0;
        if ($code !== null) {
            // discount codes: a percentage off, or a fixed amount (never below the subtotal)
            $rule = self::CODES[$code] ?? throw new InvalidArgumentException("unknown discount code: $code");
            $discount = isset($rule['percent'])
                ? (int) round($subtotal * $rule['percent'] / 100)
                : $rule['amount'];
            $discount = min($discount, $subtotal);
        }
        // VAT of 14% on the discounted subtotal, rounded to the nearest piastre
        // exercise 1: a bug to find, switched on with BUG=1
        $rate = getenv('BUG') ? 15 : 14;
        $vat = (int) round(($subtotal - $discount) * $rate / 100);

        return compact('subtotal', 'discount', 'vat') + ['total' => $subtotal - $discount + $vat];
    }
}
