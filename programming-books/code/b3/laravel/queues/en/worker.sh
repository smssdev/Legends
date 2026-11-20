# A worker starts and does them (stopping after 6 seconds, for this demo)
$ php artisan queue:work --max-time=6
  13:32:06 App\Jobs\SendOrderConfirmation … RUNNING
  sending the confirmation for order 1001 (attempt 1)
  13:32:06 App\Jobs\SendOrderConfirmation … 317.86ms DONE
  13:32:06 App\Jobs\SendOrderConfirmation … RUNNING
  sending the confirmation for order 1002 (attempt 1)
  13:32:06 App\Jobs\SendOrderConfirmation … 304.25ms DONE
  13:32:06 App\Jobs\SendOrderConfirmation … RUNNING
  sending the confirmation for order 1003 (attempt 1)
  13:32:07 App\Jobs\SendOrderConfirmation … 302.79ms FAIL
  13:32:07 App\Jobs\SendOrderConfirmation … RUNNING
  sending the confirmation for order 1004 (attempt 1)
  13:32:07 App\Jobs\SendOrderConfirmation … 1.77ms FAIL
  13:32:08 App\Jobs\SendOrderConfirmation … RUNNING
  sending the confirmation for order 1003 (attempt 2)
  13:32:08 App\Jobs\SendOrderConfirmation … 302.78ms FAIL
  13:32:10 App\Jobs\SendOrderConfirmation … RUNNING
  sending the confirmation for order 1003 (attempt 3)
  13:32:10 App\Jobs\SendOrderConfirmation … 302.87ms DONE
  13:32:12 Worker STOPPED Maximum run time exceeded
