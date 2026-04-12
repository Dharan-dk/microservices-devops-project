output "vpc_id" {
  description = "VPC ID — passed to EKS module"
  value       = aws_vpc.cloudmart_vpc.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs — for Load Balancers and EKS control plane"
  value       = aws_subnet.public_subnets[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs — for EKS worker nodes"
  value       = aws_subnet.private_subnets[*].id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID — null if enable_nat_gateway is false"
  value       = try(aws_nat_gateway.nat_gw[0].id, null)
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.cloudmart_igw.id
}