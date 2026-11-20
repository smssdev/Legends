# عمر يغيّر اسمه، ودوره
$ curl -s -X PATCH localhost:3000/unsafe/users/2 -H 'content-type: application/json' -d '{"name":"عمر","role":"admin"}' | jq -c
{"id":2,"name":"عمر","role":"admin"}
# الطلب نفسه، على المسار الآمن
$ curl -s -X PATCH localhost:3000/users/2 -H 'content-type: application/json' -d '{"name":"عمر","role":"admin"}' | jq -c
{"title":"جسم غير صالح","status":422}
