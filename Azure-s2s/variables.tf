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

variable "vnet-name" {
  description = "Virtual Network"
  type        = string
  default = "vnet1"
}

variable "subnet-name" {
  description = "Subnet Name"
  type        = string
  default = "subnet1"
}

variable "public-ip-name" {
  description = "Public IP Name"
  type = string
  default = "pubip1"
}

variable "subscription-id" {
  description = "Subscription ID"
  type = string
}

variable "tenant-id" {
  description = "Tenant ID"
  type = string
}

variable "client-id" {
  description = "Client ID"
  type = string
}

variable "client-secret" {
  description = "Client Secret"
  type = string
}
