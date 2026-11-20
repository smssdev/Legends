# Release v2: the plan shows exactly what will be replaced
$ tofu plan -var app_version=v2
  # docker_container.app[0] must be replaced
      ~ env                                         = [ # forces replacement
  # docker_container.app[1] must be replaced
      ~ env                                         = [ # forces replacement
Plan: 2 to add, 0 to change, 2 to destroy.
