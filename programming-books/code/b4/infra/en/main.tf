# a private network: only the app copies can reach the database
resource "docker_network" "private" {
  name = "bit-private"
}

resource "docker_image" "postgres" {
  name         = "postgres:18"
  keep_locally = true
}

resource "docker_image" "node" {
  name         = "node:22-slim"
  keep_locally = true
}

# the database keeps its data in a named volume, which outlives the container
resource "docker_volume" "db_data" {
  name = "bit-db-data"
}

resource "docker_container" "db" {
  name  = "bit-db"
  image = docker_image.postgres.image_id
  env   = ["POSTGRES_PASSWORD=${var.db_password}", "POSTGRES_DB=booking"]
  networks_advanced {
    name = docker_network.private.id
  }
  volumes {
    volume_name    = docker_volume.db_data.name
    container_path = "/var/lib/postgresql"
  }
}

# count: two identical copies, as Chapter 6 showed stateless copies should be
resource "docker_container" "app" {
  count   = var.app_copies
  name    = "bit-app-${count.index + 1}"
  image   = docker_image.node.image_id
  command = ["node", "-e", "require('http').createServer((q, s) => s.end(process.env.VERSION + ' from ' + require('os').hostname())).listen(3000)"]
  env     = ["VERSION=${var.app_version}", "DATABASE_HOST=${docker_container.db.name}"]
  networks_advanced {
    name = docker_network.private.id
  }
  ports {
    internal = 3000
    external = 8081 + count.index
  }
}
