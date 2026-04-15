data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["*ubuntu*24.04*amd64*server*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "agent_sg" {
  name        = "jenkins-agent-sg"
  description = "Allow SSH access for Jenkins agent"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = var.allowed_ssh_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_instance" "jenkins_static_agent" {
  # Use custom AMI if provided and enabled, otherwise use latest Ubuntu
  ami           = var.use_custom_ami && var.custom_ami_id != "" ? var.custom_ami_id : data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  # Only use user_data if NOT using custom AMI
  user_data                   = var.use_custom_ami ? null : base64encode(local.user_data_script)
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.agent_sg.id]
  associate_public_ip_address = var.associate_public_ip

  # Disable public IP association if Elastic IP will be used
  # (Elastic IP is more stable for Jenkins agent registration)

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

# Associate Elastic IP if allocation ID is provided
resource "aws_eip_association" "agent_eip" {
  count            = var.elastic_ip_allocation_id != "" ? 1 : 0
  instance_id      = aws_instance.jenkins_static_agent.id
  allocation_id    = var.elastic_ip_allocation_id
}

# Local variable for user_data script (used only when not using custom AMI)
locals {
  user_data_script = <<-EOF
              #!/bin/bash
              set -e
              apt update -y

              # Java
              apt install -y fontconfig openjdk-17-jre

              # Python
              apt install -y python3 python3-pip python3-venv git

              # Docker
              apt install -y docker.io
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu

              # AWS CLI v2 — correct method
              apt install -y curl unzip
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
                -o "/tmp/awscliv2.zip"
              unzip /tmp/awscliv2.zip -d /tmp/
              /tmp/aws/install
              rm -rf /tmp/awscliv2.zip /tmp/aws/

              # Trivy
              apt install -y wget apt-transport-https gnupg
              wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
                | gpg --dearmor -o /usr/share/keyrings/trivy.gpg
              echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
                https://aquasecurity.github.io/trivy-repo/deb generic main" \
                | tee /etc/apt/sources.list.d/trivy.list
              apt update -y
              apt install -y trivy

              # SonarScanner
              apt install -y unzip wget
              wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip \
                -O /tmp/sonar-scanner.zip
              unzip /tmp/sonar-scanner.zip -d /opt/
              ln -sf /opt/sonar-scanner-5.0.1.3006-linux/bin/sonar-scanner \
                /usr/local/bin/sonar-scanner
              rm /tmp/sonar-scanner.zip

              # Swap
              fallocate -l 2G /swapfile
              chmod 600 /swapfile
              mkswap /swapfile
              swapon /swapfile
              echo '/swapfile none swap sw 0 0' >> /etc/fstab

            EOF
}