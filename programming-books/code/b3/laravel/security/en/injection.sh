# An ordinary search
$ curl -s -G localhost:8000/api/unsafe/products -H 'Accept: application/json' --data-urlencode "q=Robot kit" | jq -c
[{"name":"Robot kit","price":45000}]
# The same search, with SQL in the input
$ curl -s -G localhost:8000/api/unsafe/products -H 'Accept: application/json' --data-urlencode "q=x' UNION SELECT email || ' ' || password, 0 FROM users --" | jq -c '.[]'
{"name":"sara@example.com $2y$12$fZzvOqSbb1yX6XGVLNEf3.u7aDM.Ix70YhutHVxr6DjiBYVkT6IXK","price":0}
{"name":"omar@example.com $2y$12$O9hBxbxQCzjoxOBhTgSTBOr3/wVxHBX6cJIV8MOSOJMQxPaSwqGWK","price":0}
# The same input, as a binding
$ curl -s -G localhost:8000/api/products -H 'Accept: application/json' --data-urlencode "q=x' UNION SELECT email || ' ' || password, 0 FROM users --" | jq -c
[]
