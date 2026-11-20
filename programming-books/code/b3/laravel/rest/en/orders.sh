# More than the stock
$ curl -s -X POST localhost:8000/api/v1/orders -H 'Content-Type: application/json' -H 'Idempotency-Key: 4f1c2a9e-order-0002' -d '{"items": [{"product_id": 1, "quantity": 50}]}' | jq
{
  "type": "https://bit-shop.example/problems/out-of-stock",
  "title": "Not enough stock",
  "status": 409,
  "detail": "Only 8 left of product 1.",
  "instance": "/api/v1/orders"
}
# Cancel, then cancel again
$ curl -s -X POST localhost:8000/api/v1/orders/1/cancel | jq -c '.data | {id, status, total}'
{"id":1,"status":"cancelled","total":{"amount":90000,"currency":"EGP"}}
$ curl -s -X POST localhost:8000/api/v1/orders/1/cancel | jq -c
{"type":"https://bit-shop.example/problems/invalid-state","title":"Order cannot be cancelled","status":409,"detail":"Order 1 is already cancelled.","instance":"/api/v1/orders/1/cancel"}
