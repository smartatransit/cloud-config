variable "map_demo_api_key" {
  type = string
}

module "map-demo" {
  source = "./modules/service"

  name      = "map-demo"
  subdomain = "map-demo"
  image     = "smartatransit/map-demo:latest"
  port      = 4000

  env = {
    API_KEY = var.map_demo_api_key
  }

  traefik_network_name = docker_network.traefik.id

  services_domain   = local.services_domain
  alternate_domains = local.alternate_services_domains
}
