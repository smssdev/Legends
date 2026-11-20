# The files this chapter adds to a new Laravel project
$ find app/Http app/Jobs app/Models bootstrap/app.php routes/api.php database/migrations/*shop* tests/Feature Dockerfile compose.yaml -type f | sort
Dockerfile
app/Http/Controllers/AuthController.php
app/Http/Controllers/Controller.php
app/Http/Controllers/OrderController.php
app/Http/Controllers/ProductController.php
app/Http/Middleware/Measure.php
app/Http/Problem.php
app/Jobs/SendOrderEmail.php
app/Models/Order.php
app/Models/OrderItem.php
app/Models/Product.php
app/Models/User.php
bootstrap/app.php
compose.yaml
database/migrations/2026_11_20_000001_create_shop_tables.php
routes/api.php
tests/Feature/ApiTest.php
