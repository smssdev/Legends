# بحث عادي
$ curl -s -G localhost:3000/unsafe/products --data-urlencode "q=عدة الروبوت" | jq -c
[{"name":"عدة الروبوت","price":45000}]
# البحث نفسه، وفي المدخل SQL
$ curl -s -G localhost:3000/unsafe/products --data-urlencode "q=x' UNION SELECT email || ' ' || password_hash, 0 FROM users --" | jq -c '.[]'
{"name":"sara@example.com scrypt$32768$nNSMalEv_zb9$Kj18iYtLJHiZb","price":0}
{"name":"omar@example.com scrypt$32768$j84P2D9FMN8n$6kpcvb9TyJSt0","price":0}
# المدخل نفسه، بصفة معامل
$ curl -s -G localhost:3000/products --data-urlencode "q=x' UNION SELECT email || ' ' || password_hash, 0 FROM users --" | jq -c
[]
