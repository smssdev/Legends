# Read a product: the ETag is its version
$ curl -si localhost:8000/api/v1/products/2 | grep -iE '^(HTTP|etag)|^\{'
HTTP/1.1 200 OK
ETag: "1"
{"data":{"id":2,"name":"Spare wheels","price":{"amount":6000,"currency":"EGP"},"stock":10,"created_at":"2026-11-01T10:00:00Z"}}
# Change it without If-Match
$ curl -s -X PATCH localhost:8000/api/v1/products/2 -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"price": 6500}' | jq -c
{"type":"https://bit-shop.example/problems/precondition-required","title":"Precondition required","status":428,"detail":"Send If-Match with the ETag you last read.","instance":"/api/v1/products/2"}
# Change it with the ETag just read
$ curl -si -X PATCH localhost:8000/api/v1/products/2 -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"price": 6500}' -H 'If-Match: "1"' | grep -iE '^(HTTP|etag)|^\{'
HTTP/1.1 200 OK
ETag: "2"
{"data":{"id":2,"name":"Spare wheels","price":{"amount":6500,"currency":"EGP"},"stock":10,"created_at":"2026-11-01T10:00:00Z"}}
# Someone else, still holding the old ETag
$ curl -s -X PATCH localhost:8000/api/v1/products/2 -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"price": 7000}' -H 'If-Match: "1"' | jq -c
{"type":"https://bit-shop.example/problems/stale","title":"The product has changed","status":412,"detail":"Someone changed it after you read it. Read it again.","instance":"/api/v1/products/2"}
