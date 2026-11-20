# What does the server send? (no JavaScript involved)
$ curl -s localhost:3000/products | grep -oE '<li><a href="[^"]+">[^<]+'
<li><a href="/products/1">Code from Zero
<li><a href="/products/2">Bit mug
<li><a href="/products/3">Bit cap
# The route handler returns JSON
$ curl -s localhost:3000/api/products
[{"id":1,"name":"Code from Zero","description":"The friendly first book of the series.","price":250},{"id":2,"name":"Bit mug","description":"A big mug for long coding nights.","price":85},{"id":3,"name":"Bit cap","description":"Keeps the sun out of your eyes.","price":120}]
