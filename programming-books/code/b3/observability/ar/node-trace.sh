# عملية دفع واحدة، وخدمتان، ورقم تتبع واحد
$ curl -s localhost:3000/checkout | jq -c
{"ok":true}
{"level":"info","time":"14:15:46.928","service":"shop:3000","reqId":"921d141fe2c375954995b46e916bae2e","req":{"method":"GET","url":"/checkout"},"msg":"incoming request"}
{"level":"info","time":"14:15:46.928","service":"shop:3000","reqId":"921d141fe2c375954995b46e916bae2e","msg":"checkout started"}
{"level":"info","time":"14:15:46.948","service":"shop:3001","reqId":"921d141fe2c375954995b46e916bae2e","req":{"method":"GET","url":"/stock/1"},"msg":"incoming request"}
{"level":"info","time":"14:15:46.965","service":"shop:3001","reqId":"921d141fe2c375954995b46e916bae2e","res":{"status":200},"responseTime":15.66,"msg":"request completed"}
{"level":"info","time":"14:15:46.972","service":"shop:3000","reqId":"921d141fe2c375954995b46e916bae2e","stock":3,"msg":"stock checked"}
{"level":"info","time":"14:15:46.973","service":"shop:3000","reqId":"921d141fe2c375954995b46e916bae2e","res":{"status":200},"responseTime":45.13,"msg":"request completed"}
