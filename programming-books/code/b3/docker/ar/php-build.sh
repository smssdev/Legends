# ابنِ الصورة
$ docker build -t shop-php .
# ما الذي بُني
$ docker image ls shop-php --format '{{.Repository}}:{{.Tag}}  {{.Size}}'
shop-php:latest  763MB
