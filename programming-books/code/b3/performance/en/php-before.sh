# 20 clients for 5 seconds, without an index
$ npx autocannon -c 20 -d 5 'localhost:8000/products?category=cables-42'
{"requests_per_s":68.6,"errors":0}
