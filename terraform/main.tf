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

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    # TEMP (you can restrict later)
    cidr_blocks = ["13.205.252.20/32", "157.50.10.255/32"] # Jenkins master IP and your IP (for testing)
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
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [aws_security_group.agent_sg.id]
  associate_public_ip_address = var.associate_public_ip

  user_data = <<-EOF
              #!/bin/bash

              apt update -y

              # Install Python & tools
              apt install -y python3 python3-pip python3-venv git

              # Install Java (REQUIRED for Sonar & Jenkins)
              apt install -y openjdk-17-jdk

              # Set JAVA_HOME (important)
              echo "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64" >> /etc/profile
              echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/profile

              # Install Docker
              apt install -y docker.io
              usermod -aG docker ubuntu

              # Install AWS CLI
              apt install -y awscli

              # Install Trivy
              apt install -y wget apt-transport-https gnupg lsb-release
              wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
              echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list
              apt update -y
              apt install -y trivy

              # Install Sonar Scanner
              apt install -y unzip
              wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
              unzip sonar-scanner-cli-*.zip -d /opt/
              ln -s /opt/sonar-scanner-*/bin/sonar-scanner /usr/local/bin/sonar-scanner

              EOF
}