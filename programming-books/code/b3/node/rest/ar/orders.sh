# أكثر من المخزون
$ curl -s -X POST localhost:3000/v1/orders -H 'Content-Type: application/json' -H 'Idempotency-Key: 4f1c2a9e-order-0002' -d '{"items": [{"product_id": 1, "quantity": 50}]}' | jq
{
  "type": "https://bit-shop.example/problems/out-of-stock",
  "title": "المخزون لا يكفي",
  "status": 409,
  "detail": "بقي 8 فقط من المنتج 1.",
  "instance": "/v1/orders"
}
# ألغِ، ثم ألغِ مرة أخرى
$ curl -s -X POST localhost:3000/v1/orders/1/cancel | jq -c '{id, status, total}'
{"id":1,"status":"cancelled","total":{"amount":90000,"currency":"EGP"}}
$ curl -s -X POST localhost:3000/v1/orders/1/cancel | jq -c
{"type":"https://bit-shop.example/problems/invalid-state","title":"لا يمكن إلغاء الطلب","status":409,"detail":"الطلب 1 حالته cancelled من قبل.","instance":"/v1/orders/1/cancel"}
