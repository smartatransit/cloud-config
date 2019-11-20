locals {
  destination = join("/", [var.destination_dir, var.file_name])
}

resource "null_resource" "file" {
  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = base64decode(var.key_material)
  }

  provisioner "file" {
    when = "create"

    content     = ""
    destination = local.destination
  }
}
