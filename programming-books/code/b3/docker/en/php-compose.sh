# The whole stack, with one command
$ docker compose up -d --wait
Volume shop_db-data Created
Network shop_default Created
Container shop-db-1 Created
Container shop-app-1 Created
Container shop-db-1 Healthy
Container shop-app-1 Healthy
# What is running, and is it healthy?
$ docker compose ps --format 'table {{.Service}}\t{{.Status}}\t{{.Ports}}'
SERVICE   STATUS                   PORTS
app       Up 5 seconds (healthy)   0.0.0.0:8080->80/tcp
db        Up 8 seconds (healthy)   5432/tcp
# The app, from the host
$ curl -s localhost:8080/products | jq -c
[{"id":1,"name":"Robot kit","price":45000},{"id":2,"name":"Spare wheels","price":6000}]
# A one-off command in a new container
$ docker compose run --rm --no-deps app php bin/count.php 2>/dev/null
{"products":2}
# The app's logs
$ docker compose logs app
172.18.0.1 - - […] "GET /products HTTP/1.1" 200 253 "-" "curl/8.5.0"
# Stop and remove everything
$ docker compose down -v
Container shop-app-1 Removed 
Container shop-db-1 Removed 
Network shop_default Removed 
Volume shop_db-data Removed 
