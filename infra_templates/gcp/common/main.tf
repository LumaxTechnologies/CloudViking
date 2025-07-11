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

output "proxy_public_ip" {
  description = "Public IP address of the Proxy host"
  value       = google_compute_instance.proxy.network_interface[0].access_config[0].nat_ip
}

output "vm_username" {
  value = "ubuntu"
} 