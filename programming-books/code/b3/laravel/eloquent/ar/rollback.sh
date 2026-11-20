# تراجع عن آخر ترحيل، ثم شغّله مرة أخرى
$ php artisan migrate:rollback --step=1 --no-ansi

   INFO  Rolling back migrations.  

  2026_11_03_000001_require_product_sku .......................... 8.52ms DONE
$ php artisan migrate --no-ansi

   INFO  Running migrations.  

  2026_11_03_000001_require_product_sku .......................... 6.70ms DONE
