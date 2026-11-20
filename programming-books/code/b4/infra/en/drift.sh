# Someone removes a container by hand; the next plan finds it
$ docker rm -f bit-app-2
bit-app-2
$ tofu plan
  # docker_container.app[1] will be created
Plan: 1 to add, 0 to change, 0 to destroy.
