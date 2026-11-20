# القناة الخاصة تحتاج إذناً
$ curl -s -o /dev/null -w '%{http_code}\n' -X POST localhost:8000/broadcasting/auth -d 'socket_id=1234.5678&channel_name=private-orders.1001'
403
