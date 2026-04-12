# Cluster Configuration
variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
  default     = "cloudmart-eks-cluster"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS cluster"
  default     = "1.31"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "Project name for resource naming"
  default     = "cloudmart"
}

# VPC and Networking
variable "vpc_id" {
  type        = string
  description = "VPC ID where the EKS cluster will be created"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for EKS nodes"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for EKS control plane (optional)"
  default     = []
}

# Node Group Configuration
variable "node_group_name" {
  type        = string
  description = "Name of the EKS managed node group"
  default     = "cloudmart-node-group"
}

variable "node_instance_types" {
  type        = list(string)
  description = "EC2 instance types for EKS nodes"
  default     = ["c7i-flex.large"]
}

variable "desired_size" {
  type        = number
  description = "Desired number of nodes"
  default     = 2
}

variable "min_size" {
  type        = number
  description = "Minimum number of nodes"
  default     = 1
}

variable "max_size" {
  type        = number
  description = "Maximum number of nodes"
  default     = 4
}

variable "disk_size" {
  type        = number
  description = "Root volume size for nodes in GB"
  default     = 50
}

variable "key_name" {
  type        = string
  description = "SSH key pair name for EC2 nodes"
  default     = "Root_EKS"
}

# Security Configuration
variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed for SSH access to nodes"
  default     = ["0.0.0.0/0"]
}

# Tags
variable "tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default = {
    Environment = "dev"
    Project     = "cloudmart"
    Owner       = "dharan"
  }
}