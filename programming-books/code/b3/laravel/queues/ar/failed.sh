# ما بقي في جدول المهام الفاشلة
$ php artisan queue:failed

  2026-11-20 13:32:40 …  redis@default App\Jobs\SendOrderConfirmation  
$ psql shop -c "SELECT substring(exception from ': (.*?) in ') AS reason FROM failed_jobs"
                reason                
--------------------------------------
 عنوان غير صالح: karim-at-example.com
(1 row)
