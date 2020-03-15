variable "jwt_signing_secret" {
  type = string
}

data "docker_registry_image" "api-gateway" {
  name = "smartatransit/api-gateway:latest"
}
resource "docker_image" "api-gateway" {
  name          = data.docker_registry_image.api-gateway.name
  pull_triggers = [data.docker_registry_image.api-gateway.sha256_digest]
  keep_locally  = true
}
module "api-gateway" {
  source = "./modules/service"

  name      = "api-gateway"
  subdomain = "api-gateway"
  image     = docker_image.api-gateway.latest
  port      = 8080

  env = {
    JWT_SIGNING_SECRET = var.jwt_signing_secret
    SERVICE_DOMAIN     = "api-gateway.${var.services_domain}"
  }

  traefik_network_name = docker_network.traefik.id
}

locals {
  gateway_info = {
    address = "https://api-gateway.${var.services_domain}/v1/verify"

    // Traefik will automagically blacklist these from the request and set
    // them based on the repsonse from the gateway.
    auth_response_headers = "X-Ataper-Auth-Id,X-Ataper-Auth-Session,X-Ataper-Auth-Anonymous,X-Ataper-Auth-Superuser,X-Ataper-Auth-Issuer,X-Ataper-Auth-Phone,X-Ataper-Auth-Email"
  }
}

module "gw-test" {
  source = "./modules/service"

  name      = "gw-test"
  subdomain = "gw-test"
  image     = "mendhak/http-https-echo"
  port      = 8080

  traefik_network_name = docker_network.traefik.id

  gateway_info = local.gateway_info
}
