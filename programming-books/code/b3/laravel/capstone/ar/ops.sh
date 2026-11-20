# ما سيجمعه Prometheus
$ curl -s localhost:8080/api/metrics | grep '^http_requests_total'
http_requests_total{method="POST",route="/api/auth/register",status="201"} 1
http_requests_total{method="POST",route="/api/auth/login",status="200"} 1
http_requests_total{method="GET",route="/api/products",status="200"} 2
http_requests_total{method="POST",route="/api/orders",status="201"} 1
http_requests_total{method="POST",route="/api/orders",status="200"} 1
http_requests_total{method="POST",route="/api/orders",status="409"} 1
http_requests_total{method="POST",route="/api/orders",status="401"} 1
http_requests_total{method="POST",route="/api/auth/login",status="401"} 4
http_requests_total{method="POST",route="/api/auth/login",status="429"} 2
# العامل أرسل البريد، مرة واحدة
$ docker compose logs worker
  15:31:48 App\Jobs\SendOrderEmail … RUNNING
{"message":"email sent","context":{"to":"sara@example.com","order_id":1},"level":200,"level_name":"INFO","channel":"production","extra":{}}
  15:31:48 App\Jobs\SendOrderEmail … DONE
# طلب واحد في سجل الـ API
$ docker compose logs app
{"level_name":"INFO","message":"request","context":{"method":"POST","url":"/api/orders","status":201,"ms":74}}
# أوقف كل شيء واحذف البيانات
$ docker compose down -v
Container shop-app-1 Removed 
Container shop-worker-1 Removed 
Container shop-db-1 Removed 
Container shop-redis-1 Removed 
Network shop_default Removed 
Volume shop_db-data Removed 
