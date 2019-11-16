output "digest" {
  value = split(":", docker_image.image.latest)[1]
}
