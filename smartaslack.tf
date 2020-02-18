variable "smartaslack_marta_api_key" {
  type = "string"
}

variable "smartaslack_signing_key" {
  type = "string"
}

module "smartaslack" {
  source = "./modules/service"

  name      = "smartaslack"
  subdomain = "smartaslack"
  image     = "smartatransit/smartaslack:build-20"
  port      = 3000

  env = {
    MARTA_API_KEY     = var.smartaslack_marta_api_key
    SLACK_SIGNING_KEY = var.smartaslack_signing_key
  }

  traefik_network_name = docker_network.traefik.id
}
