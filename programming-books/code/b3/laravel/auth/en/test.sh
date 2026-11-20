# The tests
$ php artisan test --no-ansi tests/Feature/AuthTest.php

   PASS  Tests\Feature\AuthTest
  ✓ it registers signs in and reads me                                   0.20s  
  ✓ it refuses me without a token                                        0.01s  
  ✓ it refuses the admin list to a customer                              0.01s  
  ✓ it hides other customers orders                                      0.01s  
  ✓ it rejects a token after sign out                                    0.01s  

  Tests:    5 passed (12 assertions)
  Duration: 0.31s
