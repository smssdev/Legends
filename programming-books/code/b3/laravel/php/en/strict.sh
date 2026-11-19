# Without declare(strict_types=1), PHP converts the string quietly
$ php demos/loose.php
int(90000)
int(45000)
# With it, the same call is an error
$ php demos/strict.php 2>&1 | head -n 3
int(90000)

Fatal error: Uncaught TypeError: total(): Argument #1 ($price) must be of type int, string given, called in demos/strict.php on line 11 and defined in demos/strict.php:5
