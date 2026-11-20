# Build the image
$ docker build -t shop-php .
# What was built
$ docker image ls shop-php --format '{{.Repository}}:{{.Tag}}  {{.Size}}'
shop-php:latest  763MB
