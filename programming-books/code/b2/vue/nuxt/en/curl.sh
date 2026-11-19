# What does the server send? (no JavaScript involved)
$ curl -s localhost:3000/products | grep -oE '<a href="/products/[0-9]+"[^>]*>[^<]+'
<a href="/products/1" class="">Code from Zero
<a href="/products/2" class="">Bit mug
<a href="/products/3" class="">Bit cap
# The product list is cached for a minute
$ curl -sI localhost:3000/products | grep -i cache-control
cache-control: s-maxage=60, stale-while-revalidate
# The server route returns JSON
$ curl -s localhost:3000/api/products
[{"id":1,"name":"Code from Zero","description":"The friendly first book of the series.","price":250},{"id":2,"name":"Bit mug","description":"A big mug for long coding nights.","price":85},{"id":3,"name":"Bit cap","description":"Keeps the sun out of your eyes.","price":120}]
