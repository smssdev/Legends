# قيم خارج القواعد
$ curl -s 'localhost:8000/api/v1/products?limit=500&sort=stock' | jq
{
  "type": "https://bit-shop.example/problems/invalid-request",
  "title": "طلب غير صالح",
  "status": 422,
  "instance": "/api/v1/products?limit=500&sort=stock",
  "errors": [
    {
      "field": "limit",
      "message": "الصفحة من 1 إلى 50 عنصراً."
    },
    {
      "field": "sort",
      "message": "رتّب بـ id أو price أو -price أو name."
    }
  ]
}
# منتج غير موجود
$ curl -s localhost:8000/api/v1/products/99 | jq -c
{"type":"https://bit-shop.example/problems/not-found","title":"غير موجود","status":404,"detail":"لا يوجد منتج رقمه 99.","instance":"/api/v1/products/99"}
