# Health and readiness, with the database up
$ curl -s -w ' %{http_code}\n' localhost:8000/health
{"status":"ok"} 200
$ curl -s -w ' %{http_code}\n' localhost:8000/ready
{"status":"ready"} 200
# The database stops
$ docker stop b3-pg
$ curl -s -w ' %{http_code}\n' localhost:8000/health
{"status":"ok"} 200
$ curl -s -w ' %{http_code}\n' localhost:8000/ready
{"status":"database unavailable"} 503
