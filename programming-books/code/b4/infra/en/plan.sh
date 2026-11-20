# Download the provider
$ tofu init
- Installing kreuzwerker/docker v4.5.0 to the shared cache directory...
- Installed kreuzwerker/docker v4.5.0 (signed, key ID 0DCE698927DAF8EC)
OpenTofu has been successfully initialized!
# What would change?
$ tofu plan
  # docker_container.app[0] will be created
  # docker_container.app[1] will be created
  # docker_container.db will be created
  # docker_image.node will be created
  # docker_image.postgres will be created
  # docker_network.private will be created
  # docker_volume.db_data will be created
Plan: 7 to add, 0 to change, 0 to destroy.
