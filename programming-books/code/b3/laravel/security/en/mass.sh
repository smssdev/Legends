# Omar changes his name, and his role
$ curl -s -X PATCH localhost:8000/api/unsafe/users/2 -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"name":"Omar","role":"admin"}' | jq -c
{"id":2,"name":"Omar","role":"admin"}
# The same request, on the safe route
$ curl -s -X PATCH localhost:8000/api/users/2 -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"name":"Omar","role":"admin"}' | jq -c
{"message":"The role field is prohibited.","errors":{"role":["The role field is prohibited."]}}
