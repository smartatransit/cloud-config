variable "logzio_token" {
  type = "string"
}
variable "logzio_url" {
  type = "string"
}

resource "docker_service" "log-collector" {
  name = "log-collector"

  task_spec {
    container_spec {
      image = "logzio/docker-collector-logs:c935656e24ae469ff0446f670afffbe8c917b5f81a9eb6d42edbd93e775e6bed"

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
