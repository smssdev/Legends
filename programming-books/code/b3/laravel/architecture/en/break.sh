# Someone uses the DB facade in the domain
$ ./vendor/bin/pest tests/Unit/ArchTest.php
   FAILED  Tests\Unit\ArchTest > keeps the domain free of Laravel and of the…   
  Expecting 'App\Orders\Domain' not to use 'Illuminate'.
