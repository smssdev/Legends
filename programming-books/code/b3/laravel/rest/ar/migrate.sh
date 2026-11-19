# أنشئ الجداول واملأها
$ php artisan migrate:fresh --seed --no-ansi

  Dropping all tables ............................................ 4.96ms DONE

   INFO  Preparing database.  

  Creating migration table ....................................... 3.86ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table ........................... 7.24ms DONE
  0001_01_01_000001_create_cache_table ........................... 4.53ms DONE
  0001_01_01_000002_create_jobs_table ............................ 6.61ms DONE
  2026_11_01_000001_create_products_table ........................ 2.36ms DONE
  2026_11_01_000002_create_orders_table .......................... 3.82ms DONE
  2026_11_19_203125_create_personal_access_tokens_table .......... 4.68ms DONE


   INFO  Seeding database.  

  Database\Seeders\ProductSeeder ..................................... RUNNING  
  Database\Seeders\ProductSeeder .................................. 20 ms DONE  
