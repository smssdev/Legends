# ترسل اختبارات الميزات الطلبات عبر التطبيق كله، بلا خادم
$ php artisan test --no-ansi tests/Feature/ProductApiTest.php

   PASS  Tests\Feature\ProductApiTest
  ✓ it lists the products                                                0.12s  
  ✓ it creates a product and says where it is                            0.01s  
  ✓ it refuses an invalid product with every error                       0.01s  

  Tests:    3 passed (13 assertions)
  Duration: 0.24s
