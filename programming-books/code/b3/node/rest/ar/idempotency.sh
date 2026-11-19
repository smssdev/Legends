# أنشئ طلباً، مع مفتاح عدم التكرار
$ curl -si -X POST localhost:3000/v1/orders -H 'Content-Type: application/json' -H 'Idempotency-Key: 4f1c2a9e-order-0001' -d '{"items": [{"product_id": 1, "quantity": 2}]}' | grep -iE '^(HTTP|location|idempotent)|^\{'
HTTP/1.1 201 Created
location: /v1/orders/1
{"id":1,"status":"pending","items":[{"product_id":1,"quantity":2,"price":{"amount":45000,"currency":"EGP"}}],"total":{"amount":90000,"currency":"EGP"},"created_at":"2026-11-19T19:45:37.354Z"}
# فشلت الشبكة، فأرسل العميل الطلب نفسه بالضبط مرة أخرى
$ curl -si -X POST localhost:3000/v1/orders -H 'Content-Type: application/json' -H 'Idempotency-Key: 4f1c2a9e-order-0001' -d '{"items": [{"product_id": 1, "quantity": 2}]}' | grep -iE '^(HTTP|location|idempotent)|^\{'
HTTP/1.1 201 Created
idempotent-replayed: true
location: /v1/orders/1
{"id":1,"status":"pending","items":[{"product_id":1,"quantity":2,"price":{"amount":45000,"currency":"EGP"}}],"total":{"amount":90000,"currency":"EGP"},"created_at":"2026-11-19T19:45:37.354Z"}
# المفتاح نفسه مع محتوى مختلف خطأ في العميل
$ curl -s -X POST localhost:3000/v1/orders -H 'Content-Type: application/json' -H 'Idempotency-Key: 4f1c2a9e-order-0001' -d '{"items": [{"product_id": 1, "quantity": 3}]}' | jq -c
{"type":"https://bit-shop.example/problems/idempotency-key-reused","title":"مفتاح عدم التكرار مستخدم","status":422,"detail":"استُخدم هذا المفتاح مع محتوى مختلف.","instance":"/v1/orders"}
# نقص المخزون مرة واحدة، لا مرتين
$ curl -s localhost:3000/v1/products/1 | jq -c '{id, stock}'
{"id":1,"stock":8}
