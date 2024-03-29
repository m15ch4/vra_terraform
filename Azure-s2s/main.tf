# main.tf

module "rg" {
  source = "./modules/resource_group"
  rg-name = var.rg-name
  rg-location = var.rg-location
}

module "vnet" {
  source = "git::https://github.com/m15ch4/vra_terraform.git//modules/azure_virtual_network"
  vnet-name   = var.vnet-name
  rg-location    = module.rg.resource_group_location
  rg-name     = module.rg.resource_group_name
}

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet-name
  address_prefixes     = ["10.0.1.0/24"]
  virtual_network_name = module.vnet.virtual_network_name
  resource_group_name  = module.rg.resource_group_name
}

resource "azurerm_public_ip" "publicip" {
  name                = var.public-ip-name
  location            = module.rg.resource_group_location
  resource_group_name = module.rg.resource_group_name
  allocation_method   = "Dynamic"
}


output "public_ip_address" {
  value = azurerm_public_ip.publicip.ip_address
}
