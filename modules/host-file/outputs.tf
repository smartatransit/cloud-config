output "destination" {
  value = local.destination
}

output "digest" {
  value = local.digest
}

output "docker_trigger" {
  value = random_integer.docker_trigger.result
}
