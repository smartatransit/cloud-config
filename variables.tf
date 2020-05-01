variable "smarta_domain" {
  type        = string
  description = "the core domain for all things smarta"
  default     = "ataper.net"
}

locals {
  services_domain = "services.${var.smarta_domain}"
  production_host = "smarta-data.${var.smarta_domain}"
  postgres_host   = local.production_host
  docker_host     = local.production_host
}
