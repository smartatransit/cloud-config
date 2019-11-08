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
