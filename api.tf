variable "jwt_signing_secret" {
  type = string
}
module "api-gateway" {
  source = "./modules/service"

  name      = "api-gateway"
  subdomain = "api-gateway"
  image     = "smartatransit/api-gateway:latest"
  port      = 4000

  env = {
    JWT_SIGNING_SECRET = var.jwt_signing_secret
  }

  traefik_network_name = docker_network.traefik.id
}

locals {
  gateway_info = {
    address = "api-gateway.${var.services_domain}"

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

# variable "auth0_client_id" {
#   type = string
# }
# variable "auth0_client_secret" {
#   type = string
# }
# provider "auth0" {
#   domain        = "TODO"
#   client_id     = var.auth0_client_id
#   client_secret = var.auth0_client_secret
#   debug         = true # TODO
# }

# resource "auth0_tenant" "auth0" {
#   default_audience = var.auth0_client_id
#   friendly_name    = "Ataper Transit"
#   # picture_url      = "http://mysite/logo.png"
#   # support_email    = "support@mysite"
#   # support_url      = "http://mysite/support"
#   # allowed_logout_urls = [
#   #   "http://mysite/logout"
#   # ]
#   # session_lifetime = 46000
#   # sandbox_version  = "8"
# }

//////////////////////////////////////
// / // auth0 resource servers // / //
//////////////////////////////////////
# resource "auth0_resource_server" "my_resource_server" {
#   name        = "Example Resource Server (Managed by Terraform)"
#   identifier  = "https://services.ataper.net"
#   signing_alg = "HS256"

#   scopes {
#     value       = "create:foo"
#     description = "Create foos"
#   }

#   scopes {
#     value       = "create:bar"
#     description = "Create bars"
#   }

#   allow_offline_access                            = true
#   token_lifetime                                  = 8600
#   skip_consent_for_verifiable_first_party_clients = true
# }

//
//
//
// TODO why do both clients and resource_servers have a signing_alg?
// which one is real?
//
//
//

/////////////////////////////
// / // auth0 clients // / //
/////////////////////////////
# TODO add
# resource "auth0_client" "native" {
#   name                = "Native App"
#   description         = "Test Applications Long Description"
#   app_type            = "native"
#   oidc_conformant     = true
#   callbacks           = [/* TODO */]
#   allowed_logout_urls = ["TODO"]

#   jwt_configuration { /*TODO*/ }
#   mobile {
#     // TODO
#   }
# }

# resource "auth0_client" "internal" {
#   name            = "Internal Application Access"
#   description     = "Test Applications Long Description"
#   app_type        = "non_interactive"
#   oidc_conformant = true
#   is_first_party  = true
# }


# resource "auth0_client" "test" {
#   name            = "Manual Testing"
#   app_type        = "non_interactive"
#   oidc_conformant = true
#   is_first_party  = true
# }

# ///////////////////////////////////////////////////
# // / // auth0/ataper user service sync rule // / //
# ///////////////////////////////////////////////////
# variable "auth0_client_id" {
#   type = string
# }
# variable "auth0_client_secret" {
#   type = string
# }
# resource "auth0_rule_config" "client_id" {
#   key   = "client_id"
#   value = "bar"
# }
# resource "auth0_rule_config" "client_secret" {
#   key   = "client_secret"
#   value = "bar"
# }
# resource "auth0_rule_config" "audience" {
#   key   = "audience"
#   value = "https://api-gateway.${var.services_domain}"
# }

# resource "auth0_rule" "internal_claims" {
#   name    = "empty-rule"
#   script  = file("./templates/auth0_rule-internal_claims.js")
#   enabled = true
# }

//TODO configure auth0_connections for
// - sms
// - email
// - facebook
// - apple
