resource "random_password" "third_rail_postgres" {
  length = 64
}

variable "third_rail_twitter_client_id" {
  type = string
}

variable "third_rail_twitter_client_secret" {
  type = string
}

locals {
  third_rail_build_num = 59
}

resource "postgresql_role" "third_rail" {
  name     = "third_rail"
  login    = true
  password = random_password.third_rail_postgres.result
}
resource "postgresql_database" "third_rail" {
  name  = "third_rail"
  owner = postgresql_role.third_rail.name
}

//// SERVICE ////
module "third-rail" {
  source = "./modules/service"

  name  = "third-rail"
  image = "smartatransit/third_rail:build-${local.third_rail_build_num}"
  port  = 5000

  env = {
    MARTA_API_KEY         = var.marta_api_key
    TWITTER_CLIENT_ID     = var.third_rail_twitter_client_id
    TWITTER_CLIENT_SECRET = var.third_rail_twitter_client_secret

    DB_HOST     = local.postgres_host
    DB_PORT     = 5432
    DB_NAME     = postgresql_database.third_rail.name
    DB_USERNAME = postgresql_role.third_rail.name
    DB_PASSWORD = random_password.third_rail_postgres.result
  }

  traefik_network_name = docker_network.traefik.id

  gateway_info = local.gateway_info

  services_domain   = local.services_domain
  alternate_domains = local.alternate_services_domains
}

module "third-rail-insecure" {
  source = "./modules/service"

  name  = "third-rail-insecure"
  image = "smartatransit/third_rail:build-${local.third_rail_build_num}"
  port  = 5000

  env = {
    MARTA_API_KEY         = var.marta_api_key
    TWITTER_CLIENT_ID     = var.third_rail_twitter_client_id
    TWITTER_CLIENT_SECRET = var.third_rail_twitter_client_secret

    DB_HOST     = local.postgres_host
    DB_PORT     = 5432
    DB_NAME     = postgresql_database.third_rail.name
    DB_USERNAME = postgresql_role.third_rail.name
    DB_PASSWORD = random_password.third_rail_postgres.result
  }

  traefik_network_name = docker_network.traefik.id

  services_domain   = local.services_domain
  alternate_domains = local.alternate_services_domains
}
