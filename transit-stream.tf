//// POSTGRES ////
resource "random_password" "transit_stream_postgres" {
  length = 64
}

resource "postgresql_role" "transit_stream" {
  name     = "transit_stream"
  login    = true
  password = random_password.transit_stream_postgres.result
}

resource "postgresql_grant" "transit_stream" {
  database    = postgresql_database.scrapedumper.name
  role        = postgresql_role.transit_stream.name
  schema      = "public"
  object_type = "table"
  privileges  = ["SELECT"]
}

//// SERVICE ////
module "transit-stream" {
  source = "./modules/service"

  name      = "transit-stream"
  subdomain = "transit-stream"
  image     = "smartatransit/transit-stream:latest"
  port      = 4000

  env = {
    PGPASSWORD_FILE = random_password.transit_stream_postgres.result
  }

  traefik_network_name = docker_network.traefik.id

  services_domain   = local.services_domain
  alternate_domains = local.alternate_services_domains
}
