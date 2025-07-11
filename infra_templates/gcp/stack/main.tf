provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

terraform {
  backend "local" {
  }
}

###############################################################################
# COMMON LABELS
###############################################################################
locals {
  common_labels = {
    "Customer" = var.customer
    "Environment" = var.environment
  }

  common_prefix = format("%s_%s", var.environment, var.customer)
  common_prefix_dash = format("%s-%s", var.environment, var.customer)
}

###############################################################################
# DATA RESOURCES
###############################################################################
data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
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

output "vm_names" {
  value = concat([for vm in google_compute_instance.backend : vm.labels.Type],
  [google_compute_instance.bastion.labels.Type],
  [google_compute_instance.jumpbox.labels.Type])
}

output "bastion_public_ip" {
  description = "Public IP address of the Bastion host"
  value       = google_compute_instance.bastion.network_interface[0].access_config[0].nat_ip
}

output "jumpbox_private_ip" {
  description = "Private IP address of the Jumpbox host"
  value       = google_compute_instance.jumpbox.network_interface[0].network_ip
}

output "backend_vms_private_ips" {
  description = "Mapping of backend instance names to their private IP addresses"
  value       = { for instance in google_compute_instance.backend : instance.labels.Type => instance.network_interface[0].network_ip }
}

output "vm_username" {
  value = "ubuntu"
} 