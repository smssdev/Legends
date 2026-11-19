$ php artisan test --no-ansi tests/Feature

   PASS  Tests\Feature\AnswersTest
  ✓ exercise 3 search                                                    0.14s  
  ✓ exercise 5 keys belong to a client and expire                        0.02s  

   PASS  Tests\Feature\ExampleTest
  ✓ the application returns a successful response                        0.01s  

   PASS  Tests\Feature\ShopApiTest
  ✓ it walks every page without repeats or gaps                          0.01s  
  ✓ it sorts by price highest first                                      0.01s  
  ✓ it replays an order instead of creating it twice                     0.01s  
  ✓ it refuses a stale update                                            0.01s  
  ✓ it answers 422 problems with every invalid field                     0.01s  

  Tests:    8 passed (26 assertions)
  Duration: 0.30s
