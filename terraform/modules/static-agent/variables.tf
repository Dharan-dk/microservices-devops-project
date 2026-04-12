variable "instance_type" {
  description = "Instance type for the static Jenkins agent"
  type        = string
  default     = "c7i-flex.large"
}

variable "key_name" {
  description = "SSH key pair name for EC2 access"
  type        = string
  default     = "Root_EKS"
}

variable "associate_public_ip" {
  description = "Whether to assign a public IP to the instance"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags for resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "cloudmart"
    Owner       = "dharan"
  }
}

variable "vpc_id" {
  description = "VPC ID where the security group and instance will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be launched"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}