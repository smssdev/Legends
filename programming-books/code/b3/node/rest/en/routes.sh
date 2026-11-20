# The API's routes, read from its own OpenAPI document
$ curl -s localhost:3000/openapi.json | jq -r '.paths | to_entries[] | .key as $p | .value | keys[] | ascii_upcase + " " + $p'
GET /v1/products
GET /v1/products/{id}
PATCH /v1/products/{id}
POST /v1/orders
GET /v1/orders/{id}
POST /v1/orders/{id}/cancel
