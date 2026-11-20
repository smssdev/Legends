# A request that fails
$ curl -s localhost:3000/boom | jq -c
{"title":"Server error","trace":"84335d96a3e9f93b6f45d0cf859c7bde"}
{"level":"info","time":"14:15:31.890","service":"shop:3000","reqId":"84335d96a3e9f93b6f45d0cf859c7bde","req":{"method":"GET","url":"/boom"},"msg":"incoming request"}
{"level":"error","time":"14:15:31.892","service":"shop:3000","reqId":"84335d96a3e9f93b6f45d0cf859c7bde","err":{"type":"Error","message":"payment provider timed out","at":"server.ts:84"},"msg":"payment provider timed out"}
{"level":"info","time":"14:15:31.893","service":"shop:3000","reqId":"84335d96a3e9f93b6f45d0cf859c7bde","res":{"status":500},"responseTime":2.44,"msg":"request completed"}
