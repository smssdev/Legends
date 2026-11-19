# القائمة، وتصفية
$ curl -s localhost:8000/api/products | jq -c '.data[]'
{"id":1,"name":"عدة الروبوت","price":45000,"stock":10}
{"id":2,"name":"عجلات احتياطية","price":6000,"stock":25}
{"id":3,"name":"حزمة بطارية","price":12500,"stock":0}
$ curl -s 'localhost:8000/api/products?max_price=10000' | jq -c '.data[] | [.id, .price]'
[2,6000]
# منتج واحد، ثم منتج غير موجود
$ curl -s localhost:8000/api/products/1
{"data":{"id":1,"name":"عدة الروبوت","price":45000,"stock":10}}
$ curl -s localhost:8000/api/products/9 | jq -c '{message, exception}'
{"message":"لا يوجد منتج رقمه 9.","exception":"Symfony\\Component\\HttpKernel\\Exception\\NotFoundHttpException"}
