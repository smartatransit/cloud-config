//file settings
variable "template_name" {
  type = string
}
variable "vars" {
  type = map(string)
}
variable "destination_dir" {
  type = string
}

//connection settings
variable "host" {
  type = string
}
variable "user" {
  type = string
}
variable "key_material" {
  type = string
}
