# One PHP worker: 8 clients call a route that waits 100 ms
$ PHP_CLI_SERVER_WORKERS=1 php -S localhost:8000 php/router.php
$ npx autocannon -c 8 -d 5 localhost:8000/slow
{"requests_per_s":9.81,"errors":0}
# Four PHP workers, the same load
$ PHP_CLI_SERVER_WORKERS=4 php -S localhost:8000 php/router.php
$ npx autocannon -c 8 -d 5 localhost:8000/slow
{"requests_per_s":48.4,"errors":0}
