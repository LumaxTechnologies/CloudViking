provider "aws" {
  region = var.region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_access_key
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
data "aws_availability_zones" "available" {
  state = "available"
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
  value       = aws_instance.proxy.public_ip
}

output "vm_username" {
  value = "ec2-user"
}