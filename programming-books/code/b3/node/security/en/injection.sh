# An ordinary search
$ curl -s -G localhost:3000/unsafe/products --data-urlencode "q=Robot kit" | jq -c
[{"name":"Robot kit","price":45000}]
# The same search, with SQL in the input
$ curl -s -G localhost:3000/unsafe/products --data-urlencode "q=x' UNION SELECT email || ' ' || password_hash, 0 FROM users --" | jq -c '.[]'
{"name":"sara@example.com scrypt$32768$nNSMalEv_zb9$Kj18iYtLJHiZb","price":0}
{"name":"omar@example.com scrypt$32768$j84P2D9FMN8n$6kpcvb9TyJSt0","price":0}
# The same input, as a parameter
$ curl -s -G localhost:3000/products --data-urlencode "q=x' UNION SELECT email || ' ' || password_hash, 0 FROM users --" | jq -c
[]
