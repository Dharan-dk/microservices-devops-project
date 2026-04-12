# EKS Cluster Outputs
output "cluster_id" {
  description = "The ID of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "The endpoint for your Kubernetes API server"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "The Kubernetes server version"
  value       = aws_eks_cluster.main.version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

# Node Group Outputs
output "node_group_id" {
  description = "EKS node group id"
  value       = aws_eks_node_group.main.id
}

output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = aws_eks_node_group.main.arn
}

output "node_group_status" {
  description = "Status of the EKS Node Group. One of: creating, active, deleting, failed, updating"
  value       = aws_eks_node_group.main.status
}

output "node_role_arn" {
  description = "ARN of IAM role used by node group"
  value       = aws_iam_role.eks_node_role.arn
}

# Security Group Output
output "node_security_group_id" {
  description = "Security group ID of the EKS node group"
  value       = aws_security_group.eks_node_sg.id
}

# OIDC Provider for IRSA (IAM Roles for Service Accounts)
output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = try(aws_iam_openid_connect_provider.eks.arn, "")
}

output "oidc_issuer_url" {
  description = "The URL on the IAM OIDC provider that identifies the provider"
  value       = try(aws_iam_openid_connect_provider.eks.url, "")
}

# Kubeconfig Helper
output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region $(aws configure get region) --name ${aws_eks_cluster.main.name}"
}

output "configure_kubectl" {
  description = "Configure kubectl: execute the command below"
  value       = "aws eks update-kubeconfig --region ap-south-1 --name ${aws_eks_cluster.main.name}"
}
