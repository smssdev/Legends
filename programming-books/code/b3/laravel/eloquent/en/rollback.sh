# Undo the last migration, then run it again
$ php artisan migrate:rollback --step=1 --no-ansi

   INFO  Rolling back migrations.  

  2026_11_03_000001_require_product_sku .......................... 8.00ms DONE
$ php artisan migrate --no-ansi

   INFO  Running migrations.  

  2026_11_03_000001_require_product_sku .......................... 5.96ms DONE
