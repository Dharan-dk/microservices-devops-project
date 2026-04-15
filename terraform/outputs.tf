# VPC Module Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = module.vpc.nat_gateway_id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

# Jenkins Static Agent Module Outputs
output "agent_public_ip" {
  description = "Public IP of Jenkins static agent"
  value       = module.jenkins_agent.agent_public_ip
}

output "agent_private_ip" {
  description = "Private IP of Jenkins static agent"
  value       = module.jenkins_agent.agent_private_ip
}

output "agent_security_group_id" {
  description = "Security group ID of the Jenkins agent"
  value       = module.jenkins_agent.agent_security_group_id
}

# EKS Cluster Outputs
output "eks_cluster_id" {
  description = "The ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "eks_cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint for kubectl access"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "The Kubernetes version of the EKS cluster"
  value       = module.eks.cluster_version
}

output "eks_node_group_id" {
  description = "EKS node group id"
  value       = module.eks.node_group_id
}

output "eks_configure_kubectl" {
  description = "Configure kubectl command"
  value       = module.eks.configure_kubectl
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS IRSA"
  value       = module.eks.oidc_provider_arn
}
