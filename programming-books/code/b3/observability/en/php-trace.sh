# One checkout, two services, one trace id
$ curl -s localhost:8000/checkout | jq -c
{"ok":true}
{"time":"14:15:36.386","level":"info","service":"shop:8000","trace":"8ffaf5564281114c02f9681fcf614039","msg":"incoming request","req":{"method":"GET","url":"/checkout"}}
{"time":"14:15:36.386","level":"info","service":"shop:8000","trace":"8ffaf5564281114c02f9681fcf614039","msg":"checkout started"}
{"time":"14:15:36.388","level":"info","service":"shop:8001","trace":"8ffaf5564281114c02f9681fcf614039","msg":"incoming request","req":{"method":"GET","url":"/stock/1"}}
{"time":"14:15:36.393","level":"info","service":"shop:8001","trace":"8ffaf5564281114c02f9681fcf614039","msg":"request completed","res":{"status":200},"responseTime":6.08}
{"time":"14:15:36.396","level":"info","service":"shop:8000","trace":"8ffaf5564281114c02f9681fcf614039","msg":"stock checked","stock":3}
{"time":"14:15:36.396","level":"info","service":"shop:8000","trace":"8ffaf5564281114c02f9681fcf614039","msg":"request completed","res":{"status":200},"responseTime":10.72}
