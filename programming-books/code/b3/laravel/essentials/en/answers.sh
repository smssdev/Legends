$ php artisan test --no-ansi tests/Feature/AnswersTest.php tests/Feature/ProductApiTest.php

   PASS  Tests\Feature\AnswersTest
  ✓ exercise 2 stock                                                     0.12s  
  ✓ exercise 3 price range                                               0.02s  
  ✓ exercise 4 the fake is used                                          0.01s  
  ✓ exercise 5 json only                                                 0.01s  

   PASS  Tests\Feature\ProductApiTest
  ✓ it lists the products                                                0.02s  
  ✓ it creates a product and says where it is                            0.01s  
  ✓ it refuses an invalid product with every error                       0.01s  

  Tests:    7 passed (25 assertions)
  Duration: 0.30s
