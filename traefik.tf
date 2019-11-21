variable "lets_encrypt_email" {
  type = "string"
}

variable "services_domain" {
  type    = "string"
  default = "services.ataper.net"
}

variable "apr1_traefik_dashboard_password" {
  type = "string"
}

resource "docker_network" "traefik" {
  name   = "traefik"
  driver = "overlay"
}

module "traefik_dynamic_config" {
  source = "./modules/host-file"

  template_name   = "traefik.dynamic.toml"
  host            = var.docker_host
  user            = var.terraform_host_user
  key_material    = var.terraform_host_user_key_material
  destination_dir = var.terraform_host_user_artifacts_root
}

module "traefik_config" {
  source = "./modules/host-file"

  template_name   = "traefik.toml"
  host            = var.docker_host
  user            = var.terraform_host_user
  key_material    = var.terraform_host_user_key_material
  destination_dir = var.terraform_host_user_artifacts_root

  vars = {
    lets_encrypt_email = var.lets_encrypt_email
    services_domain    = var.services_domain
    network            = docker_network.traefik.name
    dynamic_toml_path  = "/traefik.dynamic.toml"
  }
}

locals {
  acme_dot_json_path = "${var.terraform_host_user_artifacts_root}/acme.json"
}

resource "null_resource" "acme_dot_json" {
  connection {
    type        = "ssh"
    host        = var.docker_host
    user        = var.terraform_host_user
    private_key = base64decode(var.terraform_host_user_key_material)
  }

  provisioner "remote-exec" {
    when = "create"

    inline = [
      "touch ${local.acme_dot_json_path}",
      "chmod 0600 ${local.acme_dot_json_path}",
    ]
  }
}

resource "docker_service" "traefik" {
  depends_on = [module.traefik_dynamic_config, null_resource.acme_dot_json]

  name = "traefik"

  task_spec {
    force_update = module.traefik_config.docker_trigger

    container_spec {
      image = "traefik:v2.0"

      mounts {
        target = "/traefik.toml"
        source = module.traefik_config.destination
        type   = "bind"
      }
      mounts {
        target = "/traefik.dynamic.toml"
        source = module.traefik_dynamic_config.destination
        type   = "bind"
      }
      mounts {
        target = "/acme.json"
        source = local.acme_dot_json_path
        type   = "bind"
      }
      mounts {
        target = "/var/run/docker.sock"
        source = "/var/run/docker.sock"
        type   = "bind"
      }
    }

    networks = [docker_network.traefik.id]
  }

  labels {
    label = "smarta.subdomain"
    value = "dashboard"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.dashboard.entrypoints"
    value = "web-secure"
  }
  labels {
    label = "traefik.http.routers.dashboard.tls.certResolver"
    value = "main"
  }
  labels {
    label = "traefik.http.routers.dashboard.service"
    value = "api@internal"
  }
  labels {
    label = "traefik.http.services.dummy-svc.loadbalancer.server.port"
    value = "9999"
  }

  labels {
    label = "traefik.http.routers.dashboard.middlewares"
    value = "dashboard-auth"
  }
  labels {
    label = "traefik.http.middlewares.dashboard-auth.basicauth.users"
    value = "ataperteam:${var.apr1_traefik_dashboard_password}"
  }

  endpoint_spec {
    ports {
      target_port    = "80"
      published_port = "80"
    }
    ports {
      target_port    = "443"
      published_port = "443"
    }
    ports {
      target_port    = "8080"
      published_port = "8080"
    }
  }
}

resource "docker_service" "nginx" {
  depends_on = [module.traefik_config]

  name = "nginx"

  task_spec {
    container_spec {
      image = "nginx:latest"
    }

    networks = [docker_network.traefik.id]
  }

  //nginx publishes to port 80 by default - to avoid a conflict,
  //map port 80 to something random that lives behind the firewall
  //anyways
  endpoint_spec {
    ports {
      target_port    = "80"
      published_port = "22904"
    }
  }

  labels {
    label = "smarta.subdomain"
    value = "bloggo"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.nginx.entrypoints"
    value = "web-secure"
  }
  labels {
    label = "traefik.http.routers.nginx.tls.certResolver"
    value = "main"
  }
  labels {
    label = "traefik.http.services.nginx.loadbalancer.server.port"
    value = "80"
  }
}

resource "docker_service" "nginx2" {
  depends_on = [module.traefik_config]

  name = "nginx2"

  task_spec {
    container_spec {
      image = "nginx:latest"
    }

    networks = [docker_network.traefik.id]
  }

  //nginx publishes to port 80 by default - to avoid a conflict,
  //map port 80 to something random that lives behind the firewall
  //anyways
  endpoint_spec {
    ports {
      target_port    = "80"
      published_port = "22905"
    }
  }

  labels {
    label = "smarta.subdomain"
    value = "bloggedy-doo"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.nginx2.entrypoints"
    value = "web-secure"
  }
  labels {
    label = "traefik.http.routers.nginx2.tls.certResolver"
    value = "main"
  }
  labels {
    label = "traefik.http.services.nginx2.loadbalancer.server.port"
    value = "80"
  }
}
