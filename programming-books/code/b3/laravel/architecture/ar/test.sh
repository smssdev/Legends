# الاختبارات: فعل بلا قاعدة بيانات، والطبقات
$ ./vendor/bin/pest tests/Unit

   PASS  Tests\Unit\ArchTest
  ✓ keeps the domain free of Laravel and of the adapters
  ✓ lets the action use only the domain and the ports

   PASS  Tests\Unit\PlaceOrderTest
  ✓ it places an order, saves it and sends one email
  ✓ it refuses more than 10 of one product, before touching the store
  ✓ it sends no email when the store reports too little stock

  Tests:    5 passed (12 assertions)
  Duration: …
