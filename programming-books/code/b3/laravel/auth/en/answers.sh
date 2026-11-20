# Signed in on two devices, then out of both
$ curl -s -o /dev/null -w "%{http_code}\n" -X POST localhost:8000/api/auth/logout-all -H "Accept: application/json" -H "Authorization: Bearer $PHONE"
204
$ curl -s -o /dev/null -w "%{http_code}\n" localhost:8000/api/me -H "Accept: application/json" -H "Authorization: Bearer $LAPTOP"
401
# Raising the cost later
$ php artisan shop:rehash
needs rehash (10 rounds): true
needs rehash (12 rounds): false
