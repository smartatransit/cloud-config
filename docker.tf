variable "docker_ca_material" {
  type = string
}
variable "docker_cert_material" {
  type = string
}
variable "docker_key_material" {
  type = string
}

locals {
  docker_connection_options = {
    host = "tcp://${local.docker_host}:2376/"

    ca_material   = base64decode(var.docker_ca_material)
    cert_material = base64decode(var.docker_cert_material)
    key_material  = base64decode(var.docker_key_material)
  }
}

provider "docker" {
  host          = local.docker_connection_options.host
  ca_material   = local.docker_connection_options.ca_material
  cert_material = local.docker_connection_options.cert_material
  key_material  = local.docker_connection_options.key_material
}

resource "docker_service" "cron-manager" {
  name = "cron-manager"

  task_spec {
    container_spec {
      image = "crazymax/swarm-cronjob:latest"

      env = {
        TZ = "US/Eastern"
      }

      mounts {
        target = "/var/run/docker.sock"
        source = "/var/run/docker.sock"
        type   = "bind"
      }
    }

    placement {
      constraints = ["node.role==manager"]
    }
  }
}

output "docker_connection_options" {
  value = local.docker_connection_options
}
