terraform {
  required_providers {
    docker     = "~> 2.5"
    null       = "~> 2.1"
    postgresql = "~> 1.3"
    template   = "~> 2.1"
  }

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "smartatransit"

    workspaces {
      name = "cloud-config"
    }
  }
}
