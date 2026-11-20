# ما تحتاج الأدوات الأخرى معرفته بعد التطبيق
output "app_urls" {
  value = [for c in docker_container.app : "http://localhost:${c.ports[0].external}"]
}
