resource "random_password" "feedback_postgres" {
  length = 64
}

locals {
  feedback_build_num = "22"
}

resource "postgresql_role" "feedback" {
  name     = "feedback"
  login    = true
  password = random_password.feedback_postgres.result
}
resource "postgresql_database" "feedback" {
  name  = "feedback"
  owner = postgresql_role.feedback.name
}

module "feedback" {
  source = "./modules/service"

  name  = "feedback"
  image = "smartatransit/feedback:build-${local.feedback_build_num}"
  port  = 8080

  env = {
    POSTGRES_URL = "postgres://${postgresql_role.feedback.name}@${local.postgres_host}/${postgresql_database.feedback.name}"
    PGPASSWORD   = random_password.feedback_postgres.result
  }

  traefik_network_name = docker_network.traefik.id

  gateway_info = local.gateway_info

  services_domain   = local.services_domain
  alternate_domains = local.alternate_services_domains
}
