variable "smarta_domain" {
  type        = string
  description = "the core domain for all things smarta"
  default     = "smartatransit.com"
}

variable "alternate_domains" {
  type        = list(string)
  description = "TLS SANs for the main SMARTA domain"
  default     = ["smartatransit.net"]
}

locals {
  services_domain = "services.${var.smarta_domain}"
  production_host = "smarta-data.${var.smarta_domain}"
  postgres_host   = local.production_host
  docker_host     = local.production_host
}
