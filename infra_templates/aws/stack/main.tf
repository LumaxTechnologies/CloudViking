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

output "vm_names" {
  value = concat([for vm in aws_instance.backend : vm.tags.Type],
  [aws_instance.bastion.tags.Type],
  [aws_instance.jumpbox.tags.Type])
}

output "bastion_public_ip" {
  description = "Public IP address of the Bastion host"
  value       = aws_instance.bastion.public_ip
}

output "jumpbox_private_ip" {
  description = "Public IP address of the Bastion host"
  value       = aws_instance.jumpbox.private_ip
}

output "backend_vms_private_ips" {
  description = "Mapping of medium EC2 instance names to their private IP addresses"
  value       = { for instance in aws_instance.backend : instance.tags.Type => instance.private_ip }
}

output "vm_username" {
  value = "ec2-user"
}

# output "s3_buckets" {
#   description = "list of S3 buckets"
#   value = {
#     for bucket in aws_s3_bucket.bucket :
#       bucket.tags.Name => bucket.bucket_regional_domain_name
#   }
# }
