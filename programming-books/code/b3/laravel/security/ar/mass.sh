# عمر يغيّر اسمه، ودوره
$ curl -s -X PATCH localhost:8000/api/unsafe/users/2 -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"name":"عمر","role":"admin"}' | jq -c
{"id":2,"name":"عمر","role":"admin"}
# الطلب نفسه، على المسار الآمن
$ curl -s -X PATCH localhost:8000/api/users/2 -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"name":"عمر","role":"admin"}' | jq -c
{"message":"The role field is prohibited.","errors":{"role":["The role field is prohibited."]}}
