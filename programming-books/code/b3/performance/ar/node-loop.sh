# /ping، بينما ينادي عملاء آخرون /hash/sync
$ npx autocannon -c 10 -d 4 localhost:3000/ping
{"requests_per_s":103.75,"p50_ms":89,"p99_ms":470,"errors":0}
# /ping، بينما ينادي عملاء آخرون /hash/async
$ npx autocannon -c 10 -d 4 localhost:3000/ping
{"requests_per_s":22560,"p50_ms":0,"p99_ms":2,"errors":0}
# /ping وحده، للمقارنة
$ npx autocannon -c 10 -d 4 localhost:3000/ping
{"requests_per_s":33172,"p50_ms":0,"p99_ms":1,"errors":0}
