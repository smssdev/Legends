# Create a product
$ curl -si localhost:8000/api/products -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"name": "USB cable", "price": 2500}' | grep -iE '^(HTTP|location)|^\{'
HTTP/1.1 201 Created
Location: http://localhost:8000/api/products/4
{"data":{"id":4,"stock":0,"name":"USB cable","price":2500}}
# Create one with every mistake at once
$ curl -s localhost:8000/api/products -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{"price": 9.5, "stock": -1}' | jq
{
  "message": "Give the product a name. (and 2 more errors)",
  "errors": {
    "name": [
      "Give the product a name."
    ],
    "price": [
      "The price is a whole number of piastres."
    ],
    "stock": [
      "Stock cannot be negative."
    ]
  }
}
