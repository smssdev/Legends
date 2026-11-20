# 20 clients for 5 seconds, without an index
$ npx autocannon -c 20 -d 5 'localhost:3000/products?category=cables-42'
{"requests_per_s":93.6,"p50_ms":205,"p99_ms":320,"errors":0}
