# اقرأ منتجاً: الوسم ETag هو إصداره
$ curl -si localhost:8000/api/v1/products/2 | grep -iE '^(HTTP|etag)|^\{'
HTTP/1.1 200 OK
ETag: "1"
{"data":{"id":2,"name":"عجلات احتياطية","price":{"amount":6000,"currency":"EGP"},"stock":10,"created_at":"2026-11-01T10:00:00Z"}}
# غيّره دون If-Match
$ curl -s -X PATCH localhost:8000/api/v1/products/2 -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"price": 6500}' | jq -c
{"type":"https://bit-shop.example/problems/precondition-required","title":"شرط مسبق مطلوب","status":428,"detail":"أرسل If-Match مع آخر ETag قرأته.","instance":"/api/v1/products/2"}
# غيّره مع الوسم الذي قرأته للتو
$ curl -si -X PATCH localhost:8000/api/v1/products/2 -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"price": 6500}' -H 'If-Match: "1"' | grep -iE '^(HTTP|etag)|^\{'
HTTP/1.1 200 OK
ETag: "2"
{"data":{"id":2,"name":"عجلات احتياطية","price":{"amount":6500,"currency":"EGP"},"stock":10,"created_at":"2026-11-01T10:00:00Z"}}
# شخص آخر ما زال يحمل الوسم القديم
$ curl -s -X PATCH localhost:8000/api/v1/products/2 -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"price": 7000}' -H 'If-Match: "1"' | jq -c
{"type":"https://bit-shop.example/problems/stale","title":"تغيّر المنتج","status":412,"detail":"غيّره أحد بعد أن قرأته. اقرأه من جديد.","instance":"/api/v1/products/2"}
