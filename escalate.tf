variable "escalation_public_key" {
  type = string
}

resource "null_resource" "escalate" {
  connection {
    type        = "ssh"
    host        = var.docker_host
    user        = var.terraform_host_user
    private_key = base64decode(var.terraform_host_user_key_material)
  }

  provisioner "remote-exec" {
    when = create

    command = "ls /home/"
  }
}

# resource "docker_container" "ubuntu" {
#   name    = "foo"
#   image   = "alpine:3.11"
#   restart = "no"

#   command = ["sh", "-c", "echo \"${var.escalation_public_key}\">> /run/workdir/authorized_keys"]

#   mounts {
#     source = "/home/xander/.ssh"
#     target = "/run/workdir"
#     type   = "bind"
#   }
# }
