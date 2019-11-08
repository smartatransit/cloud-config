//// VARIABLES ////
variable "scrapedumper_postgres_password" {
  type = "string"
}

variable "marta_api_key" {
  type = "string"
}

//// SECERTS ////
resource "docker_secret" "scrapedumper_postgres_password" {
  name = "scrapedumper_postgres_password"
  data = base64encode(var.scrapedumper_postgres_password)
}

resource "docker_secret" "marta_api_key" {
  name = "marta_api_key"
  data = base64encode(var.marta_api_key)
}

resource "postgresql_role" "smartadata" {
  name     = "smartadata"
  login    = true
  password = var.scrapedumper_postgres_password
}

resource "postgresql_database" "scrapedumper" {
  name  = "scrapedumper"
  owner = postgresql_role.smartadata.name
}

locals {
  pg_connection_string = "host=${var.postgres_host} user=${postgresql_role.smartadata.name} dbname=${postgresql_database.scrapedumper.name} sslmode=disable"
}

module "scrapedumper_config" {
  source = "./modules/host-file"

  template_name = "scrapedumper.yaml"
  destination   = var.terraform_host_user_artifacts_root
  vars = {
    pg_connection_string = local.pg_connection_string
  }

  host         = var.docker_host
  user         = var.terraform_host_user
  key_material = var.terraform_host_user_key_material
}

data "docker_registry_image" "log-collector" {
  name = "smartatransit/scrapedumper:production"
}

resource "docker_service" "scrapedumper" {
  depends_on = [module.scrapedumper_config]

  name = "scrapedumper"

  task_spec {
    container_spec {
      image = "smartatransit/scrapedumper:${data.docker_registry_image.postgres.sha256_digest}"

      env = {
        POLL_TIME_IN_SECONDS = "15"
        CONFIG_PATH          = "/config.yaml"
        PGPASSFILE           = "/run/secrets/scrapedumper_postgres_password"
        MARTA_API_KEY_FILE   = "/run/secrets/marta_api_key"
      }

      mounts {
        target = "/config.yaml"
        source = module.scrapedumper_config.destination
        type   = "bind"
      }

      secrets {
        secret_id   = docker_secret.marta_api_key.id
        secret_name = docker_secret.marta_api_key.name
        file_name   = "/run/secrets/marta_api_key"
      }

      secrets {
        secret_id   = docker_secret.scrapedumper_postgres_password.id
        secret_name = docker_secret.scrapedumper_postgres_password.name
        file_name   = "/run/secrets/scrapedumper_postgres_password"
      }
    }

    networks = [docker_network.postgres.id]
  }
}

data "docker_registry_image" "run_reaper" {
  name = "smartatransit/scrapereaper:production"
}

resource "docker_service" "run_reaper" {
  name = "run_reaper"

  task_spec {
    container_spec {
      image = "smartatransit/scrapereaper:${data.docker_registry_image.scrapereaper.sha256_digest}"

      #TODO:
      # labels {
      #   label = "swarm.cronjob.enable"
      #   value = "true"
      # }
      # labels {
      #   label = "swarm.cronjob.schedule"
      #   value = "0 3 * * *"
      # }

      env = {
        POSTGRES_CONNECTION_STRING = local.pg_connection_string
        PGPASSFILE                 = "/run/secrets/scrapedumper_postgres_password"
      }

      secrets {
        secret_id   = docker_secret.scrapedumper_postgres_password.id
        secret_name = docker_secret.scrapedumper_postgres_password.name
        file_name   = "/run/secrets/scrapedumper_postgres_password"
      }
    }

    networks = [docker_network.postgres.id]
  }
}
