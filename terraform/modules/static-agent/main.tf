resource "aws_security_group" "static_agent_sg" {
  name        = "${var.project_name}-${var.environment}-static-agent-sg"
  description = "Security group for static agent - Allow all TCP"
  vpc_id      = var.vpc_id

  # Allow all TCP traffic from anywhere
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH from specific CIDRs
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-static-agent-sg"
    }
  )
}

# EC2 Instance
resource "aws_instance" "static_agent" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.static_agent_sg.id]
  key_name               = var.key_name
  user_data              = file("${path.module}/user-data.sh")

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = merge(
      var.tags,
      {
        Name = "${var.project_name}-${var.environment}-static-agent-root-volume"
      }
    )
  }

  monitoring = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-${var.environment}-static-agent"
    }
  )
}

# Elastic IP Association (using existing EIP)
resource "aws_eip_association" "static_agent_eip" {
  count         = var.existing_eip_allocation_id != "" ? 1 : 0
  instance_id   = aws_instance.static_agent.id
  allocation_id = var.existing_eip_allocation_id
}
