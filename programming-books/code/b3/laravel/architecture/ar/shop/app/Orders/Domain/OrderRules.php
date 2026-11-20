<?php

namespace App\Orders\Domain;

// المجال: قواعد المتجر بـ PHP عادية؛ بلا واجهات، ولا Eloquent، ولا HTTP
final class OrderRules
{
    // قاعدة من قواعد العمل، لا من قواعد قاعدة البيانات ولا API
    public const MAX_PER_PRODUCT = 10;

    /** @param list<array{product_id: int, quantity: int}> $items */
    public static function checkQuantities(array $items): void
    {
        foreach ($items as $item) {
            if ($item['quantity'] > self::MAX_PER_PRODUCT) {
                throw new TooMany('10 على الأكثر من المنتج الواحد في الطلب');
            }
        }
    }

    /** @param list<array{quantity: int, price: int}> $lines */
    public static function total(array $lines): int
    {
        return array_sum(array_map(fn ($l) => $l['quantity'] * $l['price'], $lines));
    }
}
