# Two requests in one curl command: is the connection reused?
$ curl -sv localhost:8000/products/1 localhost:8000/products/2 -o /dev/null -o /dev/null 2>&1 | grep -E 'Connected|Re-using|left intact|Closing|^< HTTP'
* Connected to localhost (127.0.0.1) port 8000
< HTTP/1.1 200 OK
* Closing connection
* Connected to localhost (127.0.0.1) port 8000
< HTTP/1.1 200 OK
* Closing connection
