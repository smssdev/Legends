# php -l only checks the syntax
$ php -l demos/bug.php
No syntax errors detected in demos/bug.php
# PHPStan checks the types without running the code
$ vendor/bin/phpstan analyse --no-progress --error-format=raw
demos/bug.php:10:Cannot call method canCancel() on Shop\OrderStatus|null.
demos/bug.php:13:Parameter #1 $amount of class Shop\Money constructor expects int, string given.
Note: Using configuration file phpstan.neon.
