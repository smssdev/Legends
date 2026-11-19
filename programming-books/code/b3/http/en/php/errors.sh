# Each mistake has its own status code
# No such product
$ curl -s localhost:8000/products/99 -w ' %{http_code}\n'
{"error":{"code":"not_found","message":"No product with this id"}} 404
# A method this address does not allow
$ curl -s -X DELETE localhost:8000/products -w ' %{http_code}\n'
{"error":{"code":"method_not_allowed","message":"Use GET or POST here"}} 405
# A body that is not JSON
$ curl -s localhost:8000/products -d 'name=Cable' -w ' %{http_code}\n'
{"error":{"code":"unsupported_media_type","message":"Send JSON"}} 415
# Broken JSON
$ curl -s localhost:8000/products -H 'Content-Type: application/json' -d '{"name": ' -w ' %{http_code}\n'
{"error":{"code":"bad_json","message":"The body is not valid JSON"}} 400
# JSON, but the fields are wrong
$ curl -s localhost:8000/products -H 'Content-Type: application/json' -d '{"price": 9.5}' -w ' %{http_code}\n'
{"error":{"code":"invalid","message":"Check the fields","fields":{"name":"Required","price":"A whole number of piastres above 0"}}} 422
# Too big
$ head -c 2000 /dev/zero | tr '\0' x | curl -s localhost:8000/products -H 'Content-Type: application/json' --data-binary @- -w ' %{http_code}\n'
{"error":{"code":"too_large","message":"At most 1 KB"}} 413
