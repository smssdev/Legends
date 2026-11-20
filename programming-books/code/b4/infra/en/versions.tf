terraform {
  required_version = ">= 1.10"
  # which provider turns these blocks into real things, at an exact version
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.5.0"
    }
  }
}

provider "docker" {}
