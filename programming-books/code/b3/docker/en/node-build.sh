# Build the image
$ docker build -t shop-node .
# What was built
$ docker image ls shop-node --format '{{.Repository}}:{{.Tag}}  {{.Size}}'
shop-node:latest  345MB
