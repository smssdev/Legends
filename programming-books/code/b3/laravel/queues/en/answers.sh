# The address is fixed; retry the failed job
$ psql shop -q -c "UPDATE orders SET email = 'karim@example.com' WHERE id = 1004"
$ php artisan queue:retry all

   INFO  Pushing failed queue jobs back onto the queue.  

  … ........................... 7.71ms DONE
$ php artisan queue:work --max-time=6
  13:32:15 App\Jobs\SendOrderConfirmation … RUNNING
  sending the confirmation for order 1004 (attempt 1)
  13:32:15 App\Jobs\SendOrderConfirmation … 319.44ms DONE
  13:32:21 Worker STOPPED Maximum run time exceeded
