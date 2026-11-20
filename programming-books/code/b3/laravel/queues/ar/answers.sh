# أُصلح العنوان؛ أعد المهمة الفاشلة
$ psql shop -q -c "UPDATE orders SET email = 'karim@example.com' WHERE id = 1004"
$ php artisan queue:retry all

   INFO  Pushing failed queue jobs back onto the queue.  

  … ........................... 7.90ms DONE
$ php artisan queue:work --max-time=6
  13:32:48 App\Jobs\SendOrderConfirmation … RUNNING
  إرسال تأكيد الطلب 1004 (المحاولة 1)
  13:32:48 App\Jobs\SendOrderConfirmation … 326.72ms DONE
  13:32:54 Worker STOPPED Maximum run time exceeded
