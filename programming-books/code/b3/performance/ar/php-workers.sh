# عامل PHP واحد: 8 عملاء ينادون مساراً ينتظر 100 مللي ثانية
$ PHP_CLI_SERVER_WORKERS=1 php -S localhost:8000 php/router.php
$ npx autocannon -c 8 -d 5 localhost:8000/slow
{"requests_per_s":9.81,"errors":0}
# أربعة عمّال PHP، والحمل نفسه
$ PHP_CLI_SERVER_WORKERS=4 php -S localhost:8000 php/router.php
$ npx autocannon -c 8 -d 5 localhost:8000/slow
{"requests_per_s":48.8,"errors":0}
