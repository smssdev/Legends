# دخول من جهازين، ثم خروج من كليهما
$ curl -s -o /dev/null -w "%{http_code}\n" -X POST localhost:8000/api/auth/logout-all -H "Accept: application/json" -H "Authorization: Bearer $PHONE"
204
$ curl -s -o /dev/null -w "%{http_code}\n" localhost:8000/api/me -H "Accept: application/json" -H "Authorization: Bearer $LAPTOP"
401
# رفع الكلفة لاحقاً
$ php artisan shop:rehash
تحتاج إعادة تجزئة (10 جولات): true
تحتاج إعادة تجزئة (12 جولة): false
