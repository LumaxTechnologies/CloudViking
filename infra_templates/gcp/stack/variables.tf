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

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region to deploy into"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone to deploy into"
  type        = string
  default     = "us-central1-a"
}

variable "credentials_file" {
  description = "Path to GCP service account key file"
  type        = string
  default     = ""
}

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
  default = {}
}

variable "instance_profiles" {
  description = "A Map of instance profiles attached to secret access"
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
  default = "e2-micro"
}

variable "jumpbox_type" {
  description = "Type of Jumpbox VM"
  type = string
  default = "e2-micro"
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
  description = "List of medium compute instances to deploy in the private subnet"
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