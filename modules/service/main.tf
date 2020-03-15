variable "name" {
  type = string
}

variable "subdomain" {
  type    = string
  default = ""
}

variable "port" {
  type = string
}

variable "traefik_network_name" {
  type = string
}

variable "env" {
  type    = map
  default = {}
}

variable "additional_labels" {
  type    = map(string)
  default = {}
}

variable "gateway_info" {
  type        = map
  default     = {}
  description = "Should be empty or have two fields - `address` and `authResponseHeaders`. If nonempty, then this "
}

locals {
  subdomain = length(var.subdomain) == 0 ? var.name : var.subdomain

  basic_traefik_labels = {
    "smarta.subdomain"                                           = local.subdomain
    "traefik.enable"                                             = "true"
    "traefik.http.routers.${var.name}.entrypoints"               = "web-secure"
    "traefik.http.routers.${var.name}.tls.certResolver"          = "main"
    "traefik.http.services.${var.name}.loadbalancer.server.port" = var.port
  }

  api_gateway_labels = {
    "traefik.http.middlewares.${var.name}-gw.forwardauth.address"             = lookup(var.gateway_info, "address", "")
    "traefik.http.middlewares.${var.name}-gw.forwardauth.authResponseHeaders" = lookup(var.gateway_info, "auth_response_headers", "")
    "traefik.http.routers.${var.name}.middlewares"                            = "${var.name}-gw@docker"
  }

  labels = merge(
    local.basic_traefik_labels,
    length(var.gateway_info) == 0 ? {} : local.api_gateway_labels,
    var.additional_labels,
  )
}

variable "image" {
  type = string
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
      env   = var.env
    }

    networks = [var.traefik_network_name]
  }

  dynamic "labels" {
    for_each = local.labels
    content {
      label = replace(labels.key, "{name}", var.name)
      value = replace(labels.value, "{name}", var.name)
    }
  }
}
