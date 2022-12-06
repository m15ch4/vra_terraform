variable "nutanix_username" {
  description = "Nutanix username"
  type        = string
  default = "admin"
}

variable "nutanix_password" {
  description = "Password for nutanix username"
  type = string
}

variable "nutanix_endpoint" {
  description = "FQDN or IP address of Prism Central"
  type = string
}

variable "nutanix_port" {
  description = "Port number"
  type = number
  default = 9440
}

