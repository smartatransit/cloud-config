resource "docker_service" "nginx3" {
  depends_on = [module.traefik_config]

  name = "nginx3"

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
      published_port = "22906"
    }
  }

  labels {
    label = "smarta.subdomain"
    value = "hope-this-works"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.nginx3.entrypoints"
    value = "web-secure"
  }
  labels {
    label = "traefik.http.routers.nginx3.tls.certResolver"
    value = "main"
  }
  labels {
    label = "traefik.http.services.nginx3.loadbalancer.server.port"
    value = "80"
  }
}
