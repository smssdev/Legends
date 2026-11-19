# Create the tables and fill them
$ php artisan migrate:fresh --seed --no-ansi

  Dropping all tables ............................................ 5.03ms DONE

   INFO  Preparing database.  

  Creating migration table ....................................... 3.84ms DONE

   INFO  Running migrations.  

  0001_01_01_000000_create_users_table ........................... 8.58ms DONE
  0001_01_01_000001_create_cache_table ........................... 4.60ms DONE
  0001_01_01_000002_create_jobs_table ............................ 8.16ms DONE
  2026_11_01_000001_create_products_table ........................ 3.22ms DONE
  2026_11_01_000002_create_orders_table .......................... 3.92ms DONE
  2026_11_19_203056_create_personal_access_tokens_table .......... 4.87ms DONE


   INFO  Seeding database.  

  Database\Seeders\ProductSeeder ..................................... RUNNING  
  Database\Seeders\ProductSeeder .................................. 22 ms DONE  
