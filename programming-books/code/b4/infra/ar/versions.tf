terraform {
  required_version = ">= 1.10"
  # أي مزوّد يحوّل هذه الكتل إلى أشياء حقيقية، بإصدار محدد
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.5.0"
    }
  }
}

provider "docker" {}
