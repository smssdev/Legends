# Artisan writes the model, its migration, factory and seeder, and a resource
$ php artisan make:model Product --migration --factory --seed --no-ansi

   INFO  Model [app/Models/Product.php] created successfully.  

   INFO  Factory [database/factories/ProductFactory.php] created successfully.  

   INFO  Migration [database/migrations/2026_11_19_203047_create_products_table.php] created successfully.  

   INFO  Seeder [database/seeders/ProductSeeder.php] created successfully.  
$ php artisan make:resource ProductResource --no-ansi

   INFO  Resource [app/Http/Resources/ProductResource.php] created successfully.  
