# One checkout, two services, one trace id
$ curl -s localhost:3000/checkout | jq -c
{"ok":true}
{"level":"info","time":"14:15:32.104","service":"shop:3000","reqId":"db944d137cf47cda9d75aeab67e0a62a","req":{"method":"GET","url":"/checkout"},"msg":"incoming request"}
{"level":"info","time":"14:15:32.104","service":"shop:3000","reqId":"db944d137cf47cda9d75aeab67e0a62a","msg":"checkout started"}
{"level":"info","time":"14:15:32.125","service":"shop:3001","reqId":"db944d137cf47cda9d75aeab67e0a62a","req":{"method":"GET","url":"/stock/1"},"msg":"incoming request"}
{"level":"info","time":"14:15:32.137","service":"shop:3001","reqId":"db944d137cf47cda9d75aeab67e0a62a","res":{"status":200},"responseTime":11.15,"msg":"request completed"}
{"level":"info","time":"14:15:32.142","service":"shop:3000","reqId":"db944d137cf47cda9d75aeab67e0a62a","stock":3,"msg":"stock checked"}
{"level":"info","time":"14:15:32.143","service":"shop:3000","reqId":"db944d137cf47cda9d75aeab67e0a62a","res":{"status":200},"responseTime":38.83,"msg":"request completed"}
