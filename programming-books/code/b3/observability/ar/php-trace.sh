# عملية دفع واحدة، وخدمتان، ورقم تتبع واحد
$ curl -s localhost:8000/checkout | jq -c
{"ok":true}
{"time":"14:15:51.150","level":"info","service":"shop:8000","trace":"5a8a7a769b6952f51bd347d433fde1e7","msg":"incoming request","req":{"method":"GET","url":"/checkout"}}
{"time":"14:15:51.151","level":"info","service":"shop:8000","trace":"5a8a7a769b6952f51bd347d433fde1e7","msg":"checkout started"}
{"time":"14:15:51.155","level":"info","service":"shop:8001","trace":"5a8a7a769b6952f51bd347d433fde1e7","msg":"incoming request","req":{"method":"GET","url":"/stock/1"}}
{"time":"14:15:51.162","level":"info","service":"shop:8001","trace":"5a8a7a769b6952f51bd347d433fde1e7","msg":"request completed","res":{"status":200},"responseTime":10.56}
{"time":"14:15:51.168","level":"info","service":"shop:8000","trace":"5a8a7a769b6952f51bd347d433fde1e7","msg":"stock checked","stock":3}
{"time":"14:15:51.168","level":"info","service":"shop:8000","trace":"5a8a7a769b6952f51bd347d433fde1e7","msg":"request completed","res":{"status":200},"responseTime":17.48}
