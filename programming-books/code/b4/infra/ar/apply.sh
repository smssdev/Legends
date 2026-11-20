# نفّذ
$ tofu apply -auto-approve
docker_volume.db_data: Creation complete after …s [id=bit-db-data]
docker_image.node: Creation complete after …s [id=sha256:…]
docker_image.postgres: Creation complete after …s [id=sha256:…]
docker_network.private: Creation complete after …s [id=426b1cef2ad0]
docker_container.db: Creation complete after …s [id=c0b564f959f8]
docker_container.app[1]: Creation complete after …s [id=9ff224863561]
docker_container.app[0]: Creation complete after …s [id=34ebe55b5214]
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.
$ tofu output app_urls
[
  "http://localhost:8081",
  "http://localhost:8082",
]
# النسختان تجيبان
$ curl -s localhost:8081; echo; curl -s localhost:8082; echo
v1 from 34ebe55b5214
v1 from 9ff224863561
# خطّط من جديد: لا شيء يُعمل
$ tofu plan
No changes. Your infrastructure matches the configuration.
