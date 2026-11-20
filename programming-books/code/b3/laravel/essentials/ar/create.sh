# مشروع Laravel جديد (ينزّل Composer الإطار وحزمه)
$ composer create-project laravel/laravel shop --no-interaction --no-ansi 2>&1 | grep -E 'Creating a|^Installing laravel|laravel/framework|Package operations|key set|Running mig'
Creating a "laravel/laravel" project at "./shop"
Installing laravel/laravel (v13.11.0)
  - Locking laravel/framework (v13.43.0)
Package operations: 110 installs, 0 updates, 0 removals
  - Installing laravel/framework (v13.43.0): Extracting archive
   INFO  Application key set successfully.  
   INFO  Running migrations.  
$ cd shop && php artisan --version
Laravel Framework 13.43.0
