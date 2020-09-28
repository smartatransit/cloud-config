variable "healthcheck_config_path" {
  type = string
}

module "healthcheck" {
  source = "./modules/service"

  name      = "healthcheck"
  subdomain = "healthcheck"
  image     = "smartatransit/healthcheck:latest"
  port      = 4000

  env = {
    CONFIG_PATH = var.healthcheck_config_path
  }

  traefik_network_name = docker_network.traefik.id

  services_domain   = local.services_domain
  alternate_domains = local.alternate_services_domains
}
