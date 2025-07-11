provider "azurerm" {
  features {}

  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

variable client_id {}
variable client_secret {}
variable tenant_id {}
variable subscription_id {}

terraform {
  backend "local" {}
}

locals {
  common_labels = {
    Customer    = var.customer
    Environment = var.environment
  }

  common_prefix      = format("%s_%s", var.environment, var.customer)
  common_prefix_dash = format("%s-%s", var.environment, var.customer)
}

###############################################################################
# OUTPUTS
###############################################################################
output "key_names" {
  description = "Names of the SSH keys"
  value = {
    for key, key_name in var.ssh_keys :
      key => key_name.name
  }
}

# output "proxy_public_ip" {
#   description = "Public IP address of the Proxy host"
#   value       = azurerm_public_ip.proxy.ip_address
# }

output "vm_names" {
  value = concat([for vm in azurerm_linux_virtual_machine.backend : vm.name],
  [azurerm_linux_virtual_machine.bastion.name],
  [azurerm_linux_virtual_machine.jumpbox.name])
}

output "resource_group_name" {
  value = "${local.common_prefix_dash}-rg"
}

output "bastion_public_ip" {
  description = "Public IP address of the Bastion host"
  value       = azurerm_public_ip.bastion.ip_address
}

output "jumpbox_private_ip" {
  description = "Public IP address of the Bastion host"
  value       = azurerm_network_interface.jumpbox_nic.private_ip_address
}

output "backend_vms_private_ips" {
  description = "Mapping of medium EC2 instance names to their private IP addresses"
  value       = { for instance in azurerm_network_interface.backend_nic : instance.tags.Type => instance.private_ip_address }
}

output "vm_username" {
  value = "azureuser"
}