output "instance_id" {
  description = "Static agent EC2 instance ID"
  value       = aws_instance.static_agent.id
}

output "private_ip" {
  description = "Private IP address of static agent"
  value       = aws_instance.static_agent.private_ip
}

output "public_ip" {
  description = "Public IP address (if available)"
  value       = aws_instance.static_agent.public_ip
}

output "elastic_ip_allocation_id" {
  description = "Elastic IP allocation ID"
  value       = var.existing_eip_allocation_id
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.static_agent_sg.id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i /path/to/Root_EKS.pem ec2-user@${aws_instance.static_agent.public_ip}"
}
