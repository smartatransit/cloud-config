variable "logzio_token" {
  type = "string"
}
variable "logzio_url" {
  type = "string"
}

data "docker_registry_image" "log-collector" {
  name = "logzio/docker-collector-logs:0.0.4"
}

module "log_collector_image" {
  source     = "./modules/docker-image"
  repository = "logzio/docker-collector-logs"
  tag        = "0.0.4"
}

resource "docker_service" "log-collector" {
  name = "log-collector"

  task_spec {
    container_spec {
      image = "logzio/docker-collector-logs:${module.log_collector_image.digest}"

      env = {
        LOGZIO_TOKEN = var.logzio_token
        LOGZIO_URL   = var.logzio_url
      }

      mounts {
        target = "/var/run/docker.sock"
        source = "/var/run/docker.sock"
        type   = "bind"
      }

      mounts {
        target = "/var/lib/docker/containers"
        source = "/var/lib/docker/containers"
        type   = "bind"
      }
    }
  }

  mode {
    replicated {
      replicas = 1
    }
  }
}
