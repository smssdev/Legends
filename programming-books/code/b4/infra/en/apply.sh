# Make it so
$ tofu apply -auto-approve
docker_volume.db_data: Creation complete after …s [id=bit-db-data]
docker_image.node: Creation complete after …s [id=sha256:…]
docker_image.postgres: Creation complete after …s [id=sha256:…]
docker_network.private: Creation complete after …s [id=ba950529a065]
docker_container.db: Creation complete after …s [id=b11ac139ef0a]
docker_container.app[0]: Creation complete after …s [id=e7f2a87bed0c]
docker_container.app[1]: Creation complete after …s [id=13bec09ee870]
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.
$ tofu output app_urls
[
  "http://localhost:8081",
  "http://localhost:8082",
]
# The two copies answer
$ curl -s localhost:8081; echo; curl -s localhost:8082; echo
v1 from e7f2a87bed0c
v1 from 13bec09ee870
# Plan again: nothing to do
$ tofu plan
No changes. Your infrastructure matches the configuration.
