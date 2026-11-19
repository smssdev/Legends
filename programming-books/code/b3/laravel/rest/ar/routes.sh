# مسارات الواجهة، من الوثيقة المولَّدة
$ curl -s localhost:8000/docs/api.json | jq -r '.paths | to_entries[] | .key as $p | .value | keys[] | ascii_upcase + " " + $p'
POST /v1/orders
GET /v1/orders/{order}
POST /v1/orders/{order}/cancel
GET /v1/products
GET /v1/products/{product}
PUT /v1/products/{product}
