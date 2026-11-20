# What Prometheus would collect
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
# The worker sent the email, once
$ docker compose logs worker
  15:30:38 App\Jobs\SendOrderEmail … RUNNING
{"message":"email sent","context":{"to":"sara@example.com","order_id":1},"level":200,"level_name":"INFO","channel":"production","extra":{}}
  15:30:38 App\Jobs\SendOrderEmail … DONE
# One request in the API's log
$ docker compose logs app
{"level_name":"INFO","message":"request","context":{"method":"POST","url":"/api/orders","status":201,"ms":68}}
# Stop everything and delete the data
$ docker compose down -v
Container shop-app-1 Removed 
Container shop-worker-1 Removed 
Container shop-redis-1 Removed 
Container shop-db-1 Removed 
Network shop_default Removed 
Volume shop_db-data Removed 
