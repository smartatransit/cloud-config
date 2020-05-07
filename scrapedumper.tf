//// VARIABLES ////
variable "scrapedumper_postgres_password" {
  type = string
}

variable "marta_api_key" {
  type = string
}

//// SECERTS ////
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
  pg_connection_string = "host=${local.postgres_host} user=${postgresql_role.smartadata.name} dbname=${postgresql_database.scrapedumper.name} sslmode=disable"
}

output "scrapedumper_database" {
  value = {
    name = postgresql_database.scrapedumper.name
  }
}

module "scrapedumper_config" {
  source = "./modules/host-file"

  template_name   = "scrapedumper.yaml"
  destination_dir = var.terraform_host_user_artifacts_root
  vars = {
    pg_connection_string = local.pg_connection_string
  }

  host         = local.docker_host
  user         = var.terraform_host_user
  key_material = var.terraform_host_user_key_material
}

resource "docker_service" "scrapedumper" {
  name = "scrapedumper"

  task_spec {
    force_update = module.scrapedumper_config.docker_trigger

    container_spec {
      image = "smartatransit/scrapedumper:latest"

      env = {
        POLL_TIME_IN_SECONDS = "15"
        CONFIG_PATH          = "/config.yaml"
        PGPASSWORD           = var.scrapedumper_postgres_password
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
    }

    networks = [docker_network.postgres.id]
  }
}

resource "docker_service" "scrapereaper" {
  name = "scrapereaper"

  task_spec {
    container_spec {
      image = "smartatransit/scrapereaper:latest"

      labels {
        label = "swarm.cronjob.enable"
        value = "true"
      }
      labels {
        label = "swarm.cronjob.schedule"
        value = "0 3 * * *"
      }

      env = {
        POSTGRES_CONNECTION_STRING = local.pg_connection_string
        PGPASSWORD                 = var.scrapedumper_postgres_password
      }
    }

    networks = [docker_network.postgres.id]

    restart_policy = {
      condition    = "none"
      max_attempts = 0
    }
  }

  mode {
    replicated {
      replicas = 0
    }
  }
}
