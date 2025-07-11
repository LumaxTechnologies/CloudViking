###############################################################################
# VARIABLES
###############################################################################

variable "customer" {
  description = "Customer Name"
  type        = string
  default     = "acme"
}

variable "environment" {
  description = "Environment Name"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region to deploy into"
  type        = string
}

# variable "aws_access_key_id" {
  
# }

# variable "aws_secret_access_key" {
  
# }

variable "ssh_keys_folder" {
  type = string
  default = "~/.ssh/"
}

variable "ssh_keys" {
  description = "Map of SSH Keys for the architecture"
  default = {}
}


variable "secrets" {
  description = "A map of secrets"
  # type = map()
  default = {}
}

variable "instance_profiles" {
  description = "A Map of instance profiles attached to secret access"
  # type = map()
  default = {}
}

variable "proxy_type" {
  description = "Type of Proxy VM"
  type = string
  default = "Standard_DS1_v2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}
