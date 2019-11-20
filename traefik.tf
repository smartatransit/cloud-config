variable "services_domain" {
  type    = "string"
  default = "services.ataper.net"
}

variable "traefik_dashboard_password" {
  type = "string"
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
    services_domain    = var.services_domain
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
  depends_on = [module.traefik_config, module.acme_dot_json]

  name = "traefik:v2.0"

  labels {
    label = "traefik.http.routers.api.rule"
    value = "Host(`traefik-dashboard.${var.services_domain}`)"
  }
  labels {
    label = "traefik.http.routers.api.service"
    value = "api@internal"
  }
  labels {
    label = "traefik.http.routers.api.middlewares"
    value = "auth"
  }
  labels {
    label = "traefik.http.middlewares.auth.basicauth.users"
    value = "ataperteam:${var.traefik_dashboard_password}"
  }

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

  #
  #
  #
  # TODO: the nginx container seems to be getting port 80 automatically
  #  once traefik is fixed, will this conflict?
  #
  #
  #

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
    value = "Host(`nginx.${var.services_domain}`)"
  }
  labels {
    label = "traefik.http.routers.web.entrypoints"
    value = "web"
  }
  labels {
    label = "traefik.http.routers.web-secure.rule"
    value = "Host(`nginx.${var.services_domain}`)"
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

  //nginx publishes to port 80 by default - to avoid a conflict,
  //map port 80 to something random that lives behind the firewall
  //anyways
  endpoint_spec {
    ports {
      target_port    = "80"
      published_port = "22904"
    }
  }
}
