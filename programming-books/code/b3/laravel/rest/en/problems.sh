# Values outside the rules
$ curl -s 'localhost:8000/api/v1/products?limit=500&sort=stock' | jq
{
  "type": "https://bit-shop.example/problems/invalid-request",
  "title": "Invalid request",
  "status": 422,
  "instance": "/api/v1/products?limit=500&sort=stock",
  "errors": [
    {
      "field": "limit",
      "message": "A page has 1 to 50 items."
    },
    {
      "field": "sort",
      "message": "Sort by id, price, -price or name."
    }
  ]
}
# A product that does not exist
$ curl -s localhost:8000/api/v1/products/99 | jq -c
{"type":"https://bit-shop.example/problems/not-found","title":"Not found","status":404,"detail":"There is no product 99.","instance":"/api/v1/products/99"}
