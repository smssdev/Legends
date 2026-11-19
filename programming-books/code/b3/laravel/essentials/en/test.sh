# The feature tests send requests through the whole app, without a server
$ php artisan test --no-ansi tests/Feature/ProductApiTest.php

   PASS  Tests\Feature\ProductApiTest
  ✓ it lists the products                                                0.09s  
  ✓ it creates a product and says where it is                            0.01s  
  ✓ it refuses an invalid product with every error                       0.01s  

  Tests:    3 passed (13 assertions)
  Duration: 0.19s
