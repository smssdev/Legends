<?php

namespace App\Orders\Domain;

// the domain: the shop's rules in plain PHP; no facades, no Eloquent, no HTTP
final class OrderRules
{
    // a rule of the business, not of the database or the API
    public const MAX_PER_PRODUCT = 10;

    /** @param list<array{product_id: int, quantity: int}> $items */
    public static function checkQuantities(array $items): void
    {
        foreach ($items as $item) {
            if ($item['quantity'] > self::MAX_PER_PRODUCT) {
                throw new TooMany('At most 10 of one product per order');
            }
        }
    }

    /** @param list<array{quantity: int, price: int}> $lines */
    public static function total(array $lines): int
    {
        return array_sum(array_map(fn ($l) => $l['quantity'] * $l['price'], $lines));
    }
}
