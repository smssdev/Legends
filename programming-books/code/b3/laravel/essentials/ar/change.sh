# غيّر حقلاً واحداً، ثم احذف
$ curl -s -X PATCH localhost:8000/api/products/4 -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"stock": 40}'
{"data":{"id":4,"stock":40,"name":"كابل USB","price":2500}}
$ curl -s -X PATCH localhost:8000/api/products/4 -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{}'
{"message":"\u0623\u0631\u0633\u0644 \u062d\u0642\u0644\u0627\u064b \u0648\u0627\u062d\u062f\u0627\u064b \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644 \u0644\u062a\u063a\u064a\u064a\u0631\u0647.","errors":{"fields":["\u0623\u0631\u0633\u0644 \u062d\u0642\u0644\u0627\u064b \u0648\u0627\u062d\u062f\u0627\u064b \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644 \u0644\u062a\u063a\u064a\u064a\u0631\u0647."]}}
$ curl -s -X DELETE localhost:8000/api/products/4 -w '%{http_code}\n'
204
# لم يعد موجوداً
$ curl -s localhost:8000/api/products/4 | jq -c '{message}'
{"message":"لا يوجد منتج رقمه 4."}
