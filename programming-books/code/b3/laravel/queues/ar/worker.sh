# عامل يبدأ وينجزها (ويتوقف بعد 6 ثوانٍ، لهذا العرض)
$ php artisan queue:work --max-time=6
  13:32:39 App\Jobs\SendOrderConfirmation … RUNNING
  إرسال تأكيد الطلب 1001 (المحاولة 1)
  13:32:39 App\Jobs\SendOrderConfirmation … 318.20ms DONE
  13:32:39 App\Jobs\SendOrderConfirmation … RUNNING
  إرسال تأكيد الطلب 1002 (المحاولة 1)
  13:32:40 App\Jobs\SendOrderConfirmation … 303.44ms DONE
  13:32:40 App\Jobs\SendOrderConfirmation … RUNNING
  إرسال تأكيد الطلب 1003 (المحاولة 1)
  13:32:40 App\Jobs\SendOrderConfirmation … 304.26ms FAIL
  13:32:40 App\Jobs\SendOrderConfirmation … RUNNING
  إرسال تأكيد الطلب 1004 (المحاولة 1)
  13:32:40 App\Jobs\SendOrderConfirmation … 2.34ms FAIL
  13:32:41 App\Jobs\SendOrderConfirmation … RUNNING
  إرسال تأكيد الطلب 1003 (المحاولة 2)
  13:32:41 App\Jobs\SendOrderConfirmation … 302.74ms FAIL
  13:32:43 App\Jobs\SendOrderConfirmation … RUNNING
  إرسال تأكيد الطلب 1003 (المحاولة 3)
  13:32:43 App\Jobs\SendOrderConfirmation … 302.81ms DONE
  13:32:45 Worker STOPPED Maximum run time exceeded
