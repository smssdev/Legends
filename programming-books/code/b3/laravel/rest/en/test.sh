# Feature tests with a fresh database for every test
$ php artisan test --no-ansi tests/Feature/ShopApiTest.php

   PASS  Tests\Feature\ShopApiTest
  ✓ it walks every page without repeats or gaps                          0.16s  
  ✓ it sorts by price highest first                                      0.01s  
  ✓ it replays an order instead of creating it twice                     0.02s  
  ✓ it refuses a stale update                                            0.01s  
  ✓ it answers 422 problems with every invalid field                     0.01s  

  Tests:    5 passed (18 assertions)
  Duration: 0.28s
