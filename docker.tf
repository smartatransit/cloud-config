variable "docker_host" {
  type = "string"
}
variable "docker_ca_material" {
  type = "string"
}
variable "docker_cert_material" {
  type = "string"
}
variable "docker_key_material" {
  type = "string"
}

provider "docker" {
  host = "tcp://${var.docker_host}:2376/"

  ca_material   = base64decode(var.docker_ca_material)
  cert_material = base64decode(var.docker_cert_material)
  key_material  = base64decode(var.docker_key_material)
}
