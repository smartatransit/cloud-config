variable "smartaslack_marta_api_key" {
  type = "string"
}

module "smartaslack" {
  source = "./modules/service"

  name      = "smartaslack"
  subdomain = "smartaslack"
  image     = "smartatransit/smartaslack:latest"
  port      = 3000

  env = {
    MARTA_API_KEY = var.smartaslack_marta_api_key
  }

  traefik_network_name = docker_network.traefik.id
}
