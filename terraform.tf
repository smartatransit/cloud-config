terraform {
  required_providers {
    docker     = "~> 5.0"
    postgresql = "~> 1.3"
    null       = "~> 2.1"
    template   = "~> 2.1"
    random     = "~> 2.1"
  }

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "smartatransit"

    workspaces {
      name = "cloud-config"
    }
  }

  required_version = "= 0.12.23"
}

variable "terraform_host_user" {
  type    = string
  default = "terraform"
}
variable "terraform_host_user_key_material" {
  type = string
}
variable "terraform_host_user_artifacts_root" {
  type = string
}
