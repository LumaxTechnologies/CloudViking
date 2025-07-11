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

variable "jumpbox_instance_profile" {
  description = "The instance profile of the jumpbox"
  type = string
  default = "db_credentials"
}

variable "bastion_type" {
  description = "Type of Bastion VM"
  type = string
  default = "Standard_DS1_v2"
}

variable "jumpbox_type" {
  description = "Type of Jumpbox VM"
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

variable "private_subnet_1_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "medium_vms" {
  description = "List of medium VM instances to deploy in the private subnet"
  type = list(object({
    name          = string
    instance_type = string
    instance_profile = string
    volume_type = string
    volume_size = number
  }))
}

variable "network_rules" {
  description = "List of network rules between resources"
  type = list(object({
    source      = string
    destination = string
    port        = number
    protocol    = string
  }))
}

# variable "s3_buckets" {
#   description = "List of S3 buckets"
#   # type        = string
# }

# variable "db_username" {
#   description = "Aurora database master username"
#   type        = string
# }

# variable "db_password" {
#   description = "Aurora database master password"
#   type        = string
#   sensitive   = true
# }


# variable "secret_key_base" {
#   description = "Rails secret key base"
#   type        = string
# }

# variable "s3_bucket_build" {
#   description = "Name of S3 bucket storing zip of Rails app"
#   type = string
# }

# variable "db_name" {
#   description = "Name of default Aurora DB"
#   type = string
#   default = "postgres"
# }

# variable "elasticbeanstalk_instance_type" {
#   description = "Instance type for the ElasticBean"
#   type = string
#   default = "t3.micro"
# }

# variable "package_path" {
  
# }

# variable "package_name" {
  
# }