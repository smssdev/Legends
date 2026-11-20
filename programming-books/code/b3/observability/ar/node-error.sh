# طلب يفشل
$ curl -s localhost:3000/boom | jq -c
{"title":"Server error","trace":"5a90163cc58100d984c70fd1decd3cf4"}
{"level":"info","time":"14:15:46.712","service":"shop:3000","reqId":"5a90163cc58100d984c70fd1decd3cf4","req":{"method":"GET","url":"/boom"},"msg":"incoming request"}
{"level":"error","time":"14:15:46.713","service":"shop:3000","reqId":"5a90163cc58100d984c70fd1decd3cf4","err":{"type":"Error","message":"payment provider timed out","at":"server.ts:84"},"msg":"payment provider timed out"}
{"level":"info","time":"14:15:46.714","service":"shop:3000","reqId":"5a90163cc58100d984c70fd1decd3cf4","res":{"status":500},"responseTime":1.44,"msg":"request completed"}
