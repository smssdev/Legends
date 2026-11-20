# All the tests
$ ./vendor/bin/pest

   PASS  Tests\Unit\ArchTest
  ✓ leaves no debugging calls in the code
  ✓ preset → laravel

   PASS  Tests\Unit\PricingTest
  ✓ it computes totals with dataset "no code: subtotal plus VAT"
  ✓ it computes totals with dataset "SAVE10 takes 10% off"
  ✓ it computes totals with dataset "FIXED50 takes 50 pounds off"
  ✓ it never lets a fixed discount go below zero
  ✓ it refuses an unknown code

   PASS  Tests\Feature\BasketsTest
  ✓ it keeps a basket touched 29 minutes ago
  ✓ it releases a basket left for 30 minutes

   PASS  Tests\Feature\OrdersTest
  ✓ it creates an order and queues one confirmation
  ✓ it refuses an order larger than the stock, and changes nothing
  ✓ it refuses a body without a quantity

  Tests:    12 passed (78 assertions)
  Duration: …
