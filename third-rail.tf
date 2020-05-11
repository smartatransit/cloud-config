variable "third_rail_twitter_client_id" {
  type = string
}

variable "third_rail_twitter_client_secret" {
  type = string
}

locals {
  third_rail_build_num = 59
}

//// SERVICE ////
module "third-rail" {
  source = "./modules/service"

  name  = "third-rail"
  image = "smartatransit/third_rail:build-${local.third_rail_build_num}"
  port  = 5000

  env = {
    MARTA_API_KEY         = var.marta_api_key
    TWITTER_CLIENT_ID     = var.third_rail_twitter_client_id
    TWITTER_CLIENT_SECRET = var.third_rail_twitter_client_secret
  }

  traefik_network_name = docker_network.traefik.id

  gateway_info = local.gateway_info
}

module "third-rail-insecure" {
  source = "./modules/service"

  name  = "third-rail-insecure"
  image = "smartatransit/third_rail:build-${local.third_rail_build_num}"
  port  = 5000

  env = {
    MARTA_API_KEY         = var.marta_api_key
    TWITTER_CLIENT_ID     = var.third_rail_twitter_client_id
    TWITTER_CLIENT_SECRET = var.third_rail_twitter_client_secret
  }

  traefik_network_name = docker_network.traefik.id
}
