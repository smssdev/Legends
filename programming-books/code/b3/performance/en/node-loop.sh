# /ping, while other clients call /hash/sync
$ npx autocannon -c 10 -d 4 localhost:3000/ping
{"requests_per_s":65.75,"p50_ms":137,"p99_ms":595,"errors":0}
# /ping, while other clients call /hash/async
$ npx autocannon -c 10 -d 4 localhost:3000/ping
{"requests_per_s":20223,"p50_ms":0,"p99_ms":2,"errors":0}
# /ping alone, for comparison
$ npx autocannon -c 10 -d 4 localhost:3000/ping
{"requests_per_s":34970,"p50_ms":0,"p99_ms":1,"errors":0}
