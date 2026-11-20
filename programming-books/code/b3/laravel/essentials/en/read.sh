# The list, and a filter
$ curl -s localhost:8000/api/products | jq -c '.data[]'
{"id":1,"name":"Robot kit","price":45000,"stock":10}
{"id":2,"name":"Spare wheels","price":6000,"stock":25}
{"id":3,"name":"Battery pack","price":12500,"stock":0}
$ curl -s 'localhost:8000/api/products?max_price=10000' | jq -c '.data[] | [.id, .price]'
[2,6000]
# One product, then one that does not exist
$ curl -s localhost:8000/api/products/1
{"data":{"id":1,"name":"Robot kit","price":45000,"stock":10}}
$ curl -s localhost:8000/api/products/9 | jq -c '{message, exception}'
{"message":"There is no product 9.","exception":"Symfony\\Component\\HttpKernel\\Exception\\NotFoundHttpException"}
