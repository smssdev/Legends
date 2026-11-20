# اختبار يفشل
$ BUG=1 ./vendor/bin/pest tests/Unit
   FAILED  Tests\Unit\PricingTest > it computes totals with dataset "no code…   
  Failed asserting that an array has a key 'vat' with the value 8550.
Failed asserting that 8550 matches expected 7980.

  at tests/Unit/PricingTest.php:9
      5▕ $lines = [['price' => 45000, 'quantity' => 1], ['price' => 6000, 'quantity' => 2]];
      6▕ 
      7▕ // صف لكل حالة: إضافة حالة سطر واحد
      8▕ it('computes totals', function (?string $code, array $expected) use ($lines) {
  ➜   9▕     expect(Pricing::total($lines, $code))->toMatchArray($expected);
     10▕ })->with([
     11▕     'no code: subtotal plus VAT' => [null, ['discount' => 0, 'vat' => 7980, 'total' => 64980]],
     12▕     'SAVE10 takes 10% off' => ['SAVE10', ['discount' => 5700, 'vat' => 7182, 'total' => 58482]],
     13▕     'FIXED50 takes 50 pounds off' => ['FIXED50', ['discount' => 5000, 'vat' => 7280, 'total' => 59280]],
