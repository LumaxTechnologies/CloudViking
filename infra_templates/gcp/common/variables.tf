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

variable "proxy_type" {
  description = "Type of Proxy VM"
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