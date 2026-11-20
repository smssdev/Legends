# الاختبارات، على PostgreSQL وRedis
$ ./vendor/bin/pest

   PASS  Tests\Feature\ApiTest
  ✓ places an order once, however many times the same key is sent
  ✓ refuses a key reused with another body
  ✓ takes no stock when one line is short
  ✓ refuses an order without a token
  ✓ pages follow each other with no gaps and no repeats

  Tests:    5 passed (14 assertions)
  Duration: …
