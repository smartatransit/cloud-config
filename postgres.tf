//// VARIABLES ////
variable "postgres_host" {
  type = "string"
}

variable "postgres_root_password" {
  type = "string"
}

variable "postgres_key_material" {
  type = "string"
}

variable "postgres_cert_material" {
  type = "string"
}

//// SECERTS ////
resource "docker_secret" "postgres_root_password" {
  name = "postgres_root_password"
  data = base64encode(var.postgres_root_password)
}
resource "docker_secret" "postgres_server_key_material" {
  name = "postgres_server_key_material"
  data = var.postgres_key_material
}

resource "docker_secret" "postgres_server_cert_material" {
  name = "postgres_server_cert_material"
  data = var.postgres_cert_material
}

//// SERVER ////
resource "docker_volume" "postgres_data" {
  name = "postgres"
}

resource "docker_network" "postgres" {
  name   = "postgres"
  driver = "overlay"
}

resource "docker_service" "postgres" {
  name = "postgres"

  task_spec {
    container_spec {
      image = "postgres:9.6"

      env = {
        PGDATA                 = "/var/lib/postgresql/data/pgdata"
        POSTGRES_PASSWORD_FILE = "/run/secrets/postgres_root_password"
      }

      secrets {
        secret_id   = docker_secret.postgres_root_password.id
        secret_name = docker_secret.postgres_root_password.name
        file_name   = "/run/secrets/postgres_root_password"
      }

      mounts {
        target = "/var/lib/postgresql/data/pgdata"
        source = docker_volume.postgres_data.name
        type   = "volume"
      }
    }

    networks = [docker_network.postgres.id]
  }

  endpoint_spec {
    ports {
      target_port  = "5432"
      publish_mode = "ingress"
    }
  }
}

//// CONNECTION ////
provider "postgresql" {
  host            = var.postgres_host
  username        = "postgres"
  password        = var.postgres_root_password
  sslmode         = "disable"
  connect_timeout = 15
}
