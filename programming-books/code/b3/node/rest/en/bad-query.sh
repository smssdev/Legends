# Values outside the rules are refused before any code runs
$ curl -s 'localhost:3000/v1/products?limit=500&sort=stock' | jq
{
  "type": "https://bit-shop.example/problems/invalid-request",
  "title": "Invalid request",
  "status": 400,
  "instance": "/v1/products?limit=500&sort=stock",
  "errors": [
    {
      "field": "querystring.limit",
      "message": "Too big: expected number to be <=50"
    },
    {
      "field": "querystring.sort",
      "message": "Invalid option: expected one of \"id\"|\"price\"|\"-price\"|\"name\""
    }
  ]
}
