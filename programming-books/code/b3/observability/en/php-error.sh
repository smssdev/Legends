# A request that fails
$ curl -s localhost:8000/boom | jq -c
{"title":"Server error","trace":"c79122972487cfe01a644d8a7000ac37"}
{"time":"14:15:36.173","level":"info","service":"shop:8000","trace":"c79122972487cfe01a644d8a7000ac37","msg":"incoming request","req":{"method":"GET","url":"/boom"}}
{"time":"14:15:36.173","level":"error","service":"shop:8000","trace":"c79122972487cfe01a644d8a7000ac37","msg":"payment provider timed out","err":{"type":"RuntimeException","at":"router.php:83"}}
{"time":"14:15:36.173","level":"info","service":"shop:8000","trace":"c79122972487cfe01a644d8a7000ac37","msg":"request completed","res":{"status":500},"responseTime":0.66}
