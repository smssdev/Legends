# ابنِ الصورة
$ docker build -t shop-node .
# ما الذي بُني
$ docker image ls shop-node --format '{{.Repository}}:{{.Tag}}  {{.Size}}'
shop-node:latest  345MB
