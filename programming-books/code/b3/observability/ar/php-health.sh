# الحياة والجاهزية، وقاعدة البيانات تعمل
$ curl -s -w ' %{http_code}\n' localhost:8000/health
{"status":"ok"} 200
$ curl -s -w ' %{http_code}\n' localhost:8000/ready
{"status":"ready"} 200
# قاعدة البيانات تتوقف
$ docker stop b3-pg
$ curl -s -w ' %{http_code}\n' localhost:8000/health
{"status":"ok"} 200
$ curl -s -w ' %{http_code}\n' localhost:8000/ready
{"status":"database unavailable"} 503
