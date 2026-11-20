# The same load, with the index
$ npx autocannon -c 20 -d 5 'localhost:3000/products?category=cables-42'
{"requests_per_s":7076.6,"p50_ms":2,"p99_ms":13,"errors":0}
