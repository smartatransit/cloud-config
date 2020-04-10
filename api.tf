data "terraform_remote_state" "auth0" {
  backend = "remote"

  config = {
    organization = "smartatransit"
    workspaces = {
      name = "auth0"
    }
  }
}

module "api-gateway" {
  source = "./modules/service"

  name      = "api-gateway"
  subdomain = "api-gateway"
  image     = "smartatransit/api-gateway:build-22"
  port      = 8080

  env = {
    AUTH0_TENANT_URL      = data.terraform_remote_state.auth0.outputs.api_url
    AUTH0_CLIENT_AUDIENCE = data.terraform_remote_state.auth0.outputs.audience
    CLIENT_ID             = data.terraform_remote_state.auth0.outputs.anonymous_client.client_id
    CLIENT_SECRET         = data.terraform_remote_state.auth0.outputs.anonymous_client.client_secret
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
