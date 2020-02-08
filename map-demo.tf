variable "map_demo_api_key" {
  type = "string"
}

module "map-demo" {
  source = "./modules/service"

  name      = "map-demo"
  subdomain = "map-demo"
  image     = "smartatransit/map-demo:build-15"
  port      = 4000

  env = {
    API_KEY = var.map_demo_api_key
  }

  traefik_network_name = docker_network.traefik.id
}
