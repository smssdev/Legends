# what other tools need to know after an apply
output "app_urls" {
  value = [for c in docker_container.app : "http://localhost:${c.ports[0].external}"]
}
