# أنشئ منتجاً
$ curl -si localhost:8000/api/products -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"name": "كابل USB", "price": 2500}' | grep -iE '^(HTTP|location)|^\{'
HTTP/1.1 201 Created
Location: http://localhost:8000/api/products/4
{"data":{"id":4,"stock":0,"name":"كابل USB","price":2500}}
# أنشئ منتجاً بكل الأخطاء معاً
$ curl -s localhost:8000/api/products -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"price": 9.5, "stock": -1}' | jq
{
  "message": "أعطِ المنتج اسماً. (and 2 more errors)",
  "errors": {
    "name": [
      "أعطِ المنتج اسماً."
    ],
    "price": [
      "السعر عدد صحيح من القروش."
    ],
    "stock": [
      "لا يجوز أن يكون المخزون سالباً."
    ]
  }
}
