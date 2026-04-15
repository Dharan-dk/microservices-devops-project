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

variable "custom_ami_id" {
  description = "Custom AMI ID with pre-installed tools (Jenkins agent, Docker, AWS CLI, Trivy, SonarScanner). If not provided, uses latest Ubuntu 24.04"
  type        = string
  default     = ""
}

variable "elastic_ip_allocation_id" {
  description = "Allocation ID of the Elastic IP to associate with the instance"
  type        = string
  default     = ""
}

variable "use_custom_ami" {
  description = "Whether to use custom AMI (true) or latest Ubuntu with user_data (false)"
  type        = bool
  default     = true
}