# ما سيجمعه Prometheus
$ curl -s localhost:3000/metrics | grep '^http_requests_total'
http_requests_total{method="POST",route="/auth/register",status="201"} 1
http_requests_total{method="POST",route="/auth/login",status="200"} 1
http_requests_total{method="GET",route="/products",status="200"} 2
http_requests_total{method="POST",route="/orders",status="201"} 1
http_requests_total{method="POST",route="/orders",status="200"} 1
http_requests_total{method="POST",route="/orders",status="409"} 1
http_requests_total{method="POST",route="/orders",status="401"} 1
http_requests_total{method="POST",route="/auth/login",status="401"} 4
http_requests_total{method="POST",route="/auth/login",status="429"} 2
# العامل أرسل البريد، مرة واحدة
$ docker compose logs worker
{"msg":"email sent","to":"sara@example.com","order_id":1}
# طلب واحد في سجل الـ API
$ docker compose logs app
{"level":30,"msg":"incoming request","method":"POST","url":"/orders"}
# أوقف كل شيء واحذف البيانات
$ docker compose down -v
Container shop-app-1 Removed 
Container shop-worker-1 Removed 
Container shop-db-1 Removed 
Container shop-redis-1 Removed 
Network shop_default Removed 
Volume shop_db-data Removed 
