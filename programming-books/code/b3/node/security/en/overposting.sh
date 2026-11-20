# Omar changes his name, and his role
$ curl -s -X PATCH localhost:3000/unsafe/users/2 -H 'content-type: application/json' -d '{"name":"Omar","role":"admin"}' | jq -c
{"id":2,"name":"Omar","role":"admin"}
# The same request, on the safe route
$ curl -s -X PATCH localhost:3000/users/2 -H 'content-type: application/json' -d '{"name":"Omar","role":"admin"}' | jq -c
{"title":"Invalid body","status":422}
