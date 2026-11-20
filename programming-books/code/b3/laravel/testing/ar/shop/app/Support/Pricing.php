<?php

namespace App\Support;

use InvalidArgumentException;

// نقية: المدخل نفسه يعطي المخرج نفسه دائماً، ولا يحدث شيء آخر
class Pricing
{
    private const CODES = ['SAVE10' => ['percent' => 10], 'FIXED50' => ['amount' => 5000]];

    /** @param list<array{price: int, quantity: int}> $lines */
    public static function total(array $lines, ?string $code = null): array
    {
        $subtotal = array_sum(array_map(fn ($l) => $l['price'] * $l['quantity'], $lines));
        $discount = 0;
        if ($code !== null) {
            // أكواد الخصم: نسبة مئوية، أو مبلغ ثابت (لا يتجاوز المجموع أبداً)
            $rule = self::CODES[$code] ?? throw new InvalidArgumentException("كود خصم مجهول: $code");
            $discount = isset($rule['percent'])
                ? (int) round($subtotal * $rule['percent'] / 100)
                : $rule['amount'];
            $discount = min($discount, $subtotal);
        }
        // ضريبة 14% على المجموع بعد الخصم، مقرَّبة إلى أقرب قرش
        // التمرين 1: خطأ يُبحث عنه، يُشغَّل بـ BUG=1
        $rate = getenv('BUG') ? 15 : 14;
        $vat = (int) round(($subtotal - $discount) * $rate / 100);

        return compact('subtotal', 'discount', 'vat') + ['total' => $subtotal - $discount + $vat];
    }
}
