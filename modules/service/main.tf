variable "name" {
  type = "string"
}

variable "subdomain" {
  type    = "string"
  default = ""
}

variable "port" {
  type = "string"
}

variable "traefik_network_name" {
  type = "string"
}

locals {
  subdomain = length(var.subdomain) == 0 ? var.name : var.subdomain
}

variable "image" {
  type = "string"
}

//If you need to access more fields on the service (like
//mounts, networks etc), add them as variables here.
variable "endpoint_spec" {
  type    = map(any)
  default = {}
}

resource "docker_service" "service" {
  name = var.name

  task_spec {
    container_spec {
      image = var.image
    }

    networks = [var.traefik_network_name]
  }

  endpoint_spec {
    # ports = var.endpoint_spec.ports

    # for_each = var.endpoint_spec
    # content {
    # }

    dynamic "ports" {
      for_each = var.endpoint_spec.ports
      content {
        target_port    = ports.value.target_port
        published_port = ports.value.published_port
      }
    }
  }

  labels {
    label = "smarta.subdomain"
    value = local.subdomain
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.${var.name}.entrypoints"
    value = "web-secure"
  }
  labels {
    label = "traefik.http.routers.${var.name}.tls.certResolver"
    value = "main"
  }
  labels {
    label = "traefik.http.services.${var.name}.loadbalancer.server.port"
    value = var.port
  }
}
