# طلبان في أمر curl واحد: هل يُعاد استخدام الاتصال؟
$ curl -sv localhost:3000/products/1 localhost:3000/products/2 -o /dev/null -o /dev/null 2>&1 | grep -E 'Connected|Re-using|left intact|Closing|^< HTTP'
* Connected to localhost (127.0.0.1) port 3000
< HTTP/1.1 200 OK
* Connection #0 to host localhost left intact
* Re-using existing connection with host localhost
< HTTP/1.1 200 OK
* Connection #0 to host localhost left intact
