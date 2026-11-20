# Change one field, then delete
$ curl -s -X PATCH localhost:8000/api/products/4 -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"stock": 40}'
{"data":{"id":4,"stock":40,"name":"USB cable","price":2500}}
$ curl -s -X PATCH localhost:8000/api/products/4 -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{}'
{"message":"Send at least one field to change.","errors":{"fields":["Send at least one field to change."]}}
$ curl -s -X DELETE localhost:8000/api/products/4 -w '%{http_code}\n'
204
# Gone
$ curl -s localhost:8000/api/products/4 | jq -c '{message}'
{"message":"There is no product 4."}
