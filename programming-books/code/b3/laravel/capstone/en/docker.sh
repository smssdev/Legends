# The image
$ docker build -t shop-api .
$ docker image ls shop-api
shop-api:latest  841MB
# First the database and Redis, then the migrations, as their own step
$ docker compose up -d --wait db redis > /dev/null 2>&1
$ docker compose run --rm app php artisan migrate --force --seed
Creating migration table … DONE
0001_01_01_000000_create_users_table … DONE
0001_01_01_000001_create_cache_table … DONE
0001_01_01_000002_create_jobs_table … DONE
2026_11_20_000001_create_shop_tables … DONE
2026_11_20_153012_create_personal_access_tokens_table … DONE
# Then the API and the worker
$ docker compose up -d --wait
Container shop-db-1 Healthy
Container shop-redis-1 Healthy
Container shop-worker-1 Started
Container shop-app-1 Started
Container shop-worker-1 Healthy
Container shop-app-1 Healthy
$ docker compose ps --format 'table {{.Service}}\t{{.Status}}'
SERVICE   STATUS
app       Up 5 seconds (healthy)
db        Up 10 seconds (healthy)
redis     Up 11 seconds (healthy)
worker    Up 5 seconds
