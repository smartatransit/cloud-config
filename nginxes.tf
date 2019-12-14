module "nginx_service" {
  source = "./modules/service"

  name  = "nginx"
  image = "nginx:latest"
  port  = 80

  traefik_network_name = docker_network.traefik.id

  //nginx publishes to port 80 on the host by default - to avoid a
  //conflict, map port 80 to something random that lives behind the
  //firewall anyways. Other services probably won't need this.
  endpoint_spec = {
    ports = [{
      target_port    = "80"
      published_port = "22904"
    }]
  }
}

module "nginx2_service" {
  source = "./modules/service"

  name      = "nginx2"
  subdomain = "bloggedy-doo"
  image     = "nginx:latest"
  port      = 80

  traefik_network_name = docker_network.traefik.id

  //nginx publishes to port 80 on the host by default - to avoid a
  //conflict, map port 80 to something random that lives behind the
  //firewall anyways. Other services probably won't need this.
  endpoint_spec = {
    ports = [{
      target_port    = "80"
      published_port = "22905"
    }]
  }
}
