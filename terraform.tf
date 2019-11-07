terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "smartatransit"

    workspaces {
      name = "cloud-config"
    }
  }
}
