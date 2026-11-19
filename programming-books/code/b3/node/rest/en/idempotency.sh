# Create an order, with an idempotency key
$ curl -si -X POST localhost:3000/v1/orders -H 'Content-Type: application/json' -H 'Idempotency-Key: 4f1c2a9e-order-0001' -d '{"items": [{"product_id": 1, "quantity": 2}]}' | grep -iE '^(HTTP|location|idempotent)|^\{'
HTTP/1.1 201 Created
location: /v1/orders/1
{"id":1,"status":"pending","items":[{"product_id":1,"quantity":2,"price":{"amount":45000,"currency":"EGP"}}],"total":{"amount":90000,"currency":"EGP"},"created_at":"2026-11-19T19:45:33.808Z"}
# The network failed, so the client sends exactly the same request again
$ curl -si -X POST localhost:3000/v1/orders -H 'Content-Type: application/json' -H 'Idempotency-Key: 4f1c2a9e-order-0001' -d '{"items": [{"product_id": 1, "quantity": 2}]}' | grep -iE '^(HTTP|location|idempotent)|^\{'
HTTP/1.1 201 Created
idempotent-replayed: true
location: /v1/orders/1
{"id":1,"status":"pending","items":[{"product_id":1,"quantity":2,"price":{"amount":45000,"currency":"EGP"}}],"total":{"amount":90000,"currency":"EGP"},"created_at":"2026-11-19T19:45:33.808Z"}
# The same key with a different body is a client bug
$ curl -s -X POST localhost:3000/v1/orders -H 'Content-Type: application/json' -H 'Idempotency-Key: 4f1c2a9e-order-0001' -d '{"items": [{"product_id": 1, "quantity": 3}]}' | jq -c
{"type":"https://bit-shop.example/problems/idempotency-key-reused","title":"Idempotency key reused","status":422,"detail":"This key was used with a different body.","instance":"/v1/orders"}
# The stock went down once, not twice
$ curl -s localhost:3000/v1/products/1 | jq -c '{id, stock}'
{"id":1,"stock":8}
