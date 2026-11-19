# التقرير نفسه بطريقتين: عُدّ الاستعلامات
$ SHOP_STRICT=false php artisan shop:report lazy
lazy  200 طلبات, 201 استعلامات, 205 ms
$ SHOP_STRICT=false php artisan shop:report eager
eager 200 طلبات, 2 استعلامات, 39 ms
