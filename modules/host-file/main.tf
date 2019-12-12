data "template_file" "file" {
  template = "${file("${path.root}/templates/${var.template_name}")}"
  vars     = var.vars
}

locals {
  digest      = md5(data.template_file.file.rendered)
  destination = join("/", [var.destination_dir, var.template_name])
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
    destination = local.destination
  }
}

//Anytime the digest changes, generate a new random number.
//This can be used to trigger a Docker service to restart.
resource "random_integer" "docker_trigger" {
  min     = 1
  max     = 100000
  keepers = { digest = local.digest }
}
