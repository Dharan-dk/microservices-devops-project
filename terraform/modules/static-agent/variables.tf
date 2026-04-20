variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used to prefix all resource names"
  type        = string
  default     = "cloudmart"
}

variable "vpc_id" {
  description = "VPC ID where the static agent will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID for the static agent EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "c7i-flex.large"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "ami_id" {
  description = "AMI ID (Ubuntu 24.04 LTS)"
  type        = string
  default     = "ami-05d2d839d4f73aafb" # Ubuntu 24.04 LTS in ap-south-1
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = "Root_EKS"
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_elastic_ip" {
  description = "Create and associate Elastic IP"
  type        = bool
  default     = false
}

variable "existing_eip_allocation_id" {
  description = "Existing Elastic IP allocation ID to associate with static agent"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "cloudmart"
    ManagedBy   = "terraform"
  }
}
