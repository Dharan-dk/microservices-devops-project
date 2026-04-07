variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

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