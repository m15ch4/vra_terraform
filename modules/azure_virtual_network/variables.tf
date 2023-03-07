variable "vnet-name" {
  description = "Virtual Network"
  type        = string
  default = "vnet1"
}

variable "rg-name" {
  description = "Resource Group Name"
  type        = string
  default = "rg1"
}

variable "rg-location" {
  description = "Resource Group Location"
  type        = string
  default = "westus2"
}