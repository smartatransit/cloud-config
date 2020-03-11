variable "third_rail_twitter_client_id" {
  type = "string"
}

variable "third_rail_twitter_client_secret" {
  type = "string"
}

//// SERVICE ////
module "third-rail" {
  source = "./modules/service"

  name      = "third-rail"
  subdomain = "third-rail"
  image     = "smartatransit/third_rail:build-17"
  port      = 5000

  env = {
    MARTA_API_KEY             = var.marta_api_key
    TWITTER_CLIENT_ID         = var.third_rail_twitter_client_id
    TWITTER_CLIENT_SECERT     = var.third_rail_twitter_client_secret
  }

  traefik_network_name = docker_network.traefik.id
}
