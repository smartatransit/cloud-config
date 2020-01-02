module "map-demo" {
  source = "./modules/service"

  name      = "map-demo"
  subdomain = "map-demo"
  image     = "smartatransit/map-demo:latest"
  port      = 4000

  traefik_network_name = docker_network.traefik.id
}
