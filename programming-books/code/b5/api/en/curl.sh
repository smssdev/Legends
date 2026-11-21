$ curl -s localhost:8080/menu/1
{
  "id": 1,
  "name": "Latte",
  "price": 45,
  "image": "latte"
}
$ curl -s localhost:8080/menu/9 -w '\nHTTP %{http_code}\n'
{
  "error": "No drink 9"
}
HTTP 404
$ curl -s -X POST localhost:8080/orders -H 'Content-Type: application/json' -d '{"name": "Sara", "items": [1, 4]}' -w '\nHTTP %{http_code}\n'
{
  "id": 2,
  "name": "Sara",
  "total": 105
}
HTTP 201
$ curl -s -X POST localhost:8080/orders -H 'Content-Type: application/json' -d '{"name": "", "items": [1]}' -w '\nHTTP %{http_code}\n'
{
  "error": "A name is needed"
}
HTTP 400
