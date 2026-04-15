output "agent_public_ip" {
  description = "Public IP of Jenkins static agent"
  value       = aws_instance.jenkins_static_agent.public_ip
}

output "agent_private_ip" {
  description = "Private IP of Jenkins static agent"
  value       = aws_instance.jenkins_static_agent.private_ip
}

output "agent_elastic_ip" {
  description = "Elastic IP associated with Jenkins agent (if configured)"
  value       = var.elastic_ip_allocation_id != "" ? aws_eip_association.agent_eip[0].public_ip : null
}

output "jenkins_master_eip" {
  description = "Elastic IP of Jenkins master"
  value       = "13.205.252.20"
}

output "agent_security_group_id" {
  description = "Security group ID of the Jenkins agent"
  value       = aws_security_group.agent_sg.id
}

output "ami_id_used" {
  description = "AMI ID being used (custom or latest Ubuntu)"
  value       = aws_instance.jenkins_static_agent.ami
}

output "instance_type_used" {
  description = "Instance type deployed"
  value       = aws_instance.jenkins_static_agent.instance_type
}