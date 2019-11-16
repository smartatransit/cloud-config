data "template_file" "file" {
  template = "${file("${path.root}/templates/${var.template_name}")}"
  vars     = var.vars
}

locals {
  digest = md5(data.template_file.file.rendered)
}

resource "null_resource" "file" {
  triggers = {
    digest = local.digest
  }

  connection {
    type        = "ssh"
    host        = var.host
    user        = var.user
    private_key = base64decode(var.key_material)
  }

  provisioner "file" {
    content     = data.template_file.file.rendered
    destination = var.destination
  }
}
