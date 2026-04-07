output "agent_public_ip" {
  description = "Public IP of Jenkins static agent"
  value       = aws_instance.jenkins_static_agent.public_ip
}

output "agent_private_ip" {
  description = "Private IP of Jenkins static agent"
  value       = aws_instance.jenkins_static_agent.private_ip
}

output "jenkins_master_eip" {
  description = "Elastic IP of Jenkins master"
  value       = "13.205.252.20"
}