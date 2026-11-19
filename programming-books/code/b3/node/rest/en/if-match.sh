# Read a product: the ETag is its version
$ curl -si localhost:3000/v1/products/2 | grep -iE '^(HTTP|etag)|^\{'
HTTP/1.1 200 OK
etag: "1"
{"id":2,"name":"Spare wheels","price":{"amount":6000,"currency":"EGP"},"stock":10,"created_at":"2026-11-01T10:00:00.000Z"}
# Change it without If-Match
$ curl -s -X PATCH localhost:3000/v1/products/2 -H 'Content-Type: application/json' -d '{"price": 6500}' | jq -c
{"type":"https://bit-shop.example/problems/precondition-required","title":"Precondition required","status":428,"detail":"Send If-Match with the ETag you last read.","instance":"/v1/products/2"}
# Change it with the ETag just read
$ curl -si -X PATCH localhost:3000/v1/products/2 -H 'Content-Type: application/json' -d '{"price": 6500}' -H 'If-Match: "1"' | grep -iE '^(HTTP|etag)|^\{'
HTTP/1.1 200 OK
etag: "2"
{"id":2,"name":"Spare wheels","price":{"amount":6500,"currency":"EGP"},"stock":10,"created_at":"2026-11-01T10:00:00.000Z"}
# Someone else, still holding the old ETag, tries the same
$ curl -s -X PATCH localhost:3000/v1/products/2 -H 'Content-Type: application/json' -d '{"price": 7000}' -H 'If-Match: "1"' | jq -c
{"type":"https://bit-shop.example/problems/stale","title":"The product has changed","status":412,"detail":"Someone changed it after you read it. Read it again.","instance":"/v1/products/2"}
