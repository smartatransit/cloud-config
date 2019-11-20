variable "stack_domain" {
  type    = "string"
  default = "services.ataper.net"
}

resource "docker_network" "traefik" {
  name   = "traefik"
  driver = "overlay"
}

module "traefik_config" {
  source = "./modules/host-file"

  template_name   = "traefik.toml"
  host            = var.docker_host
  user            = var.terraform_host_user
  key_material    = var.terraform_host_user_key_material
  destination_dir = var.terraform_host_user_artifacts_root

  vars = {
    lets_encrypt_email = "team@ataper.net" // TODO
    services_domain    = var.stack_domain
    network            = docker_network.traefik.name
  }

}

module "acme_dot_json" {
  source = "./modules/host-file-unmanaged"

  file_name       = "acme.json"
  host            = var.docker_host
  user            = var.terraform_host_user
  key_material    = var.terraform_host_user_key_material
  destination_dir = var.terraform_host_user_artifacts_root
}

resource "docker_service" "traefik" {
  depends_on = [module.traefik_config]

  name = "traefik"

  task_spec {
    container_spec {
      image = "traefik:v2.0.0-rc3"

      mounts {
        target = "/traefik.toml"
        source = module.traefik_config.destination
        type   = "bind"
      }

      mounts {
        target = "/acme.json"
        source = module.acme_dot_json.destination
        type   = "bind"
      }
    }

    networks = [docker_network.traefik.id]
  }

  endpoint_spec {
    ports { target_port = "80" }
    ports { target_port = "443" }
    ports { target_port = "8080" }
  }
}

resource "docker_service" "nginx" {
  depends_on = [module.traefik_config]

  name = "nginx"

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.web.rule"
    value = "Host(`nginx.${var.stack_domain}`)"
  }
  labels {
    label = "traefik.http.routers.web.entrypoints"
    value = "web"
  }
  labels {
    label = "traefik.http.routers.web-secure.rule"
    value = "Host(`nginx.${var.stack_domain}`)"
  }
  labels {
    label = "traefik.http.routers.web-secure.entrypoints"
    value = "web"
  }
  labels {
    label = "traefik.http.routers.web-secure.tls.certResolver"
    value = "main"
  }

  task_spec {
    container_spec {
      image = "nginx:latest"
    }

    networks = [docker_network.traefik.id]
  }
}
