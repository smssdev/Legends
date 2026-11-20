# An account
$ curl -s localhost:8080/api/auth/register -H 'content-type: application/json' -H 'accept: application/json' -d '{"email":"sara@example.com","name":"Sara","password":"a long password"}' | jq -c
{"id":1,"email":"sara@example.com","name":"Sara"}
# A token
$ TOKEN=$(curl -s localhost:8080/api/auth/login -H 'content-type: application/json' -H 'accept: application/json' -d '{"email":"sara@example.com","password":"a long password"}' | jq -r .token)
# The first page of products, cheapest first
$ curl -s 'localhost:8080/api/products?limit=2' | jq -c
{"data":[{"id":2,"name":"Spare wheels","price":6000,"stock":50},{"id":4,"name":"Battery pack","price":9000,"stock":30}],"next_cursor":"eyJwcmljZSI6OTAwMCwiaWQiOjQsIl9wb2ludHNUb05leHRJdGVtcyI6dHJ1ZX0"}
# The next page, from the cursor
$ curl -s 'localhost:8080/api/products?limit=2&cursor=eyJwcmljZSI6OTAwMCwiaWQiOjQsIl9wb2ludHNUb05leHRJdGVtcyI6dHJ1ZX0' | jq -c '.data[].name, .next_cursor'
"Soldering iron"
"Sensor set"
"eyJwcmljZSI6MjUwMDAsImlkIjo1LCJfcG9pbnRzVG9OZXh0SXRlbXMiOnRydWV9"
# An order, with a key the client chose
$ curl -s -i localhost:8080/api/orders -H 'content-type: application/json' -H 'accept: application/json' -H "authorization: Bearer $TOKEN" -H 'idempotency-key: order-0001' -d '{"items":[{"product_id":1,"quantity":2},{"product_id":2,"quantity":4}]}' | grep -iE '^HTTP|^idempotent|^\{' | sed 's/\r//'
HTTP/1.1 201 Created
{"id":1,"total":114000,"created_at":"2026-11-20T15:30:37.000000Z","items":[{"product_id":1,"quantity":2,"price":45000},{"product_id":2,"quantity":4,"price":6000}]}
# The network failed and the client sends it again, with the same key
$ curl -s -i localhost:8080/api/orders -H 'content-type: application/json' -H 'accept: application/json' -H "authorization: Bearer $TOKEN" -H 'idempotency-key: order-0001' -d '{"items":[{"product_id":1,"quantity":2},{"product_id":2,"quantity":4}]}' | grep -iE '^HTTP|^idempotent|^\{' | sed 's/\r//'
HTTP/1.1 200 OK
Idempotent-Replayed: true
{"id":1,"total":114000,"created_at":"2026-11-20T15:30:37.000000Z","items":[{"product_id":1,"quantity":2,"price":45000},{"product_id":2,"quantity":4,"price":6000}]}
# More than the stock
$ curl -s localhost:8080/api/orders -H 'content-type: application/json' -H 'accept: application/json' -H "authorization: Bearer $TOKEN" -H 'idempotency-key: order-0002' -d '{"items":[{"product_id":1,"quantity":4}]}' | jq -c
{"title":"Not enough stock","status":409,"detail":"Product 1 has 3 left.","instance":"/api/orders"}
# No token
$ curl -s localhost:8080/api/orders -H 'content-type: application/json' -H 'accept: application/json' -H 'idempotency-key: order-0003' -d '{"items":[{"product_id":1,"quantity":4}]}' | jq -c
{"title":"Not signed in","status":401,"detail":"Send a valid token: Authorization: Bearer <token>.","instance":"/api/orders"}
# Someone guesses a password
$ for i in 1 2 3 4 5 6; do curl -s -o /dev/null -w '%{http_code} ' localhost:8080/api/auth/login -H 'content-type: application/json' -H 'accept: application/json' -d '{"email":"sara@example.com","password":"guess"}'; done; echo
401 401 401 401 429 429 
