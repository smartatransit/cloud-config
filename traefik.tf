variable "lets_encrypt_email" {
  type = string
}

variable "apr1_traefik_dashboard_password" {
  type = string
}

resource "docker_network" "traefik" {
  name   = "traefik"
  driver = "overlay"
}

module "traefik_dynamic_config" {
  source = "./modules/host-file"

  template_name   = "traefik.dynamic.toml"
  host            = local.docker_host
  user            = var.terraform_host_user
  key_material    = var.terraform_host_user_key_material
  destination_dir = var.terraform_host_user_artifacts_root
}

locals {
  host_snis = [
    for domain in local.all_services_domains :
    "`{{ default .Name (index .Labels \\\"smarta.subdomain\\\") }}.${domain}`"
  ]
}

module "traefik_config" {
  source = "./modules/host-file"

  template_name   = "traefik.toml"
  host            = local.docker_host
  user            = var.terraform_host_user
  key_material    = var.terraform_host_user_key_material
  destination_dir = var.terraform_host_user_artifacts_root

  vars = {
    lets_encrypt_email = var.lets_encrypt_email
    network            = docker_network.traefik.name
    dynamic_toml_path  = "/traefik.dynamic.toml"

    default_rule = "HostSNI(${join(",", local.host_snis)})"
  }
}

locals {
  acme_dot_json_path = "${var.terraform_host_user_artifacts_root}/acme.json"
}

resource "null_resource" "acme_dot_json" {
  connection {
    type        = "ssh"
    host        = local.docker_host
    user        = var.terraform_host_user
    private_key = base64decode(var.terraform_host_user_key_material)
  }

  provisioner "remote-exec" {
    when = create

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
    value = "smartateam:${var.apr1_traefik_dashboard_password}"
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
  }
}

output "traefik_network" {
  value = docker_network.traefik
}
