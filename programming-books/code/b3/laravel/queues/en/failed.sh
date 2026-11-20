# What is left in the failed jobs table
$ php artisan queue:failed

  2026-11-20 13:32:07 …  redis@default App\Jobs\SendOrderConfirmation  
$ psql shop -c "SELECT substring(exception from ': (.*?) in ') AS reason FROM failed_jobs"
                reason                 
---------------------------------------
 invalid address: karim-at-example.com
(1 row)
