# حساب
$ curl -s localhost:3000/auth/register -H 'content-type: application/json' -d '{"email":"sara@example.com","password":"a long password"}' | jq -c
{"id":1,"email":"sara@example.com"}
# رمز
$ TOKEN=$(curl -s localhost:3000/auth/login -H 'content-type: application/json' -d '{"email":"sara@example.com","password":"a long password"}' | jq -r .token)
# أول صفحة من المنتجات، الأرخص أولاً
$ curl -s 'localhost:3000/products?limit=2' | jq -c
{"data":[{"id":2,"name":"عجلات احتياطية","price":6000,"stock":50},{"id":4,"name":"حزمة بطاريات","price":9000,"stock":30}],"next_cursor":"WzkwMDAsNF0"}
# الصفحة التالية، من المؤشر
$ curl -s 'localhost:3000/products?limit=2&cursor=WzkwMDAsNF0' | jq -c '.data[].name, .next_cursor'
"كاوية لحام"
"طقم حساسات"
"WzI1MDAwLDVd"
# طلب، بمفتاح اختاره العميل
$ curl -s -i localhost:3000/orders -H 'content-type: application/json' -H "authorization: Bearer $TOKEN" -H 'idempotency-key: order-0001' -d '{"items":[{"product_id":1,"quantity":2},{"product_id":2,"quantity":4}]}' | grep -iE '^HTTP|^idempotent|^\{' | sed 's/\r//'
HTTP/1.1 201 Created
{"id":1,"total":114000,"created_at":"2026-11-20T15:34:38.226Z","items":[{"product_id":1,"quantity":2,"price":45000},{"product_id":2,"quantity":4,"price":6000}]}
# فشلت الشبكة فأعاد العميل الإرسال، بالمفتاح نفسه
$ curl -s -i localhost:3000/orders -H 'content-type: application/json' -H "authorization: Bearer $TOKEN" -H 'idempotency-key: order-0001' -d '{"items":[{"product_id":1,"quantity":2},{"product_id":2,"quantity":4}]}' | grep -iE '^HTTP|^idempotent|^\{' | sed 's/\r//'
HTTP/1.1 200 OK
idempotent-replayed: true
{"id":1,"total":114000,"created_at":"2026-11-20T15:34:38.226Z","items":[{"product_id":1,"quantity":2,"price":45000},{"product_id":2,"quantity":4,"price":6000}]}
# أكثر من المخزون
$ curl -s localhost:3000/orders -H 'content-type: application/json' -H "authorization: Bearer $TOKEN" -H 'idempotency-key: order-0002' -d '{"items":[{"product_id":1,"quantity":4}]}' | jq -c
{"title":"المخزون لا يكفي","status":409,"detail":"بقي من المنتج 1: 3.","instance":"/orders"}
# بلا رمز
$ curl -s localhost:3000/orders -H 'content-type: application/json' -H 'idempotency-key: order-0003' -d '{"items":[{"product_id":1,"quantity":4}]}' | jq -c
{"title":"لم تسجّل الدخول","status":401,"detail":"أرسل رمزاً صالحاً: Authorization: Bearer <token>.","instance":"/orders"}
# أحدهم يخمّن كلمة مرور
$ for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w '%{http_code} ' localhost:3000/auth/login -H 'content-type: application/json' -d '{"email":"sara@example.com","password":"guess"}'; done; echo
401 401 401 401 429 429 
