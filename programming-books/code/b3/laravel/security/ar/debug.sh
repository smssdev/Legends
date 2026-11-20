# خطأ مع APP_DEBUG=true
$ curl -s localhost:8000/api/boom -H 'Accept: application/json' | jq '{message, exception, file, line}'
{
  "message": "SQLSTATE[42P01]: Undefined table: 7 ERROR:  relation \"missing_table\" does not exist\nLINE 1: SELECT * FROM missing_table\n                      ^ (Connection: pgsql, Host: 127.0.0.1, Port: 5432, Database: shop, SQL: SELECT * FROM missing_table)",
  "exception": "Illuminate\\Database\\QueryException",
  "file": "vendor/laravel/framework/src/Illuminate/Database/Connection.php",
  "line": 864
}
