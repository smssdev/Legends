# The image
$ docker build -t shop-api .
$ docker image ls shop-api
shop-api:latest  371MB
# The whole system: database, Redis, the API and the worker
$ docker compose up -d --wait
Container shop-db-1 Started
Container shop-redis-1 Started
Container shop-db-1 Healthy
Container shop-redis-1 Healthy
Container shop-worker-1 Started
Container shop-app-1 Started
Container shop-worker-1 Healthy
Container shop-app-1 Healthy
$ docker compose ps --format 'table {{.Service}}\t{{.Status}}'
SERVICE   STATUS
app       Up 5 seconds (healthy)
db        Up 8 seconds (healthy)
redis     Up 8 seconds (healthy)
worker    Up 5 seconds
