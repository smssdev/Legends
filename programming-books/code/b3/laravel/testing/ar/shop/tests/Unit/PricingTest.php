<?php

use App\Support\Pricing;

$lines = [['price' => 45000, 'quantity' => 1], ['price' => 6000, 'quantity' => 2]];

// صف لكل حالة: إضافة حالة سطر واحد
it('computes totals', function (?string $code, array $expected) use ($lines) {
    expect(Pricing::total($lines, $code))->toMatchArray($expected);
})->with([
    'no code: subtotal plus VAT' => [null, ['discount' => 0, 'vat' => 7980, 'total' => 64980]],
    'SAVE10 takes 10% off' => ['SAVE10', ['discount' => 5700, 'vat' => 7182, 'total' => 58482]],
    'FIXED50 takes 50 pounds off' => ['FIXED50', ['discount' => 5000, 'vat' => 7280, 'total' => 59280]],
]);

it('never lets a fixed discount go below zero', function () {
    expect(Pricing::total([['price' => 3000, 'quantity' => 1]], 'FIXED50'))
        ->toBe(['subtotal' => 3000, 'discount' => 3000, 'vat' => 0, 'total' => 0]);
});

it('refuses an unknown code', function () {
    Pricing::total([['price' => 3000, 'quantity' => 1]], 'FREE');
})->throws(InvalidArgumentException::class, 'FREE');
