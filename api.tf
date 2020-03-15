variable "jwt_signing_secret" {
  type = string
}
module "api-gateway" {
  source = "./modules/service"

  name      = "api-gateway"
  subdomain = "api-gateway"
  image     = "smartatransit/api-gateway:staging"
  port      = 4000

  env = {
    JWT_SIGNING_SECRET = var.jwt_signing_secret
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
