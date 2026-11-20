# A few requests, one with its own trace id
$ curl -s localhost:3000/products/1 | jq -c
{"id":1,"name":"Robot kit","price":45000}
$ curl -s localhost:3000/products/9 | jq -c
{"title":"Not found"}
$ curl -s localhost:3000/products/1 -H 'traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01' | jq -c
{"id":1,"name":"Robot kit","price":45000}
