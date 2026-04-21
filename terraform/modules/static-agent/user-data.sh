#!/bin/bash
set -e

echo "===== Updating system ====="
apt update -y

echo "===== Installing base packages ====="
apt install -y \
  curl \
  wget \
  unzip \
  git \
  jq \
  apt-transport-https \
  ca-certificates \
  gnupg \
  lsb-release

echo "===== Install AWS CLI v2 ====="
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip awscliv2.zip
./aws/install

echo "===== Install kubectl ====="
curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

echo "===== Install eksctl ====="
curl --silent --location \
"https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
| tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin

echo "===== Install Docker ====="
apt install -y docker.io
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

echo "===== Install Helm ====="
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo "===== Install Java 17 (Jenkins agent requirement) ====="
apt install -y openjdk-17-jdk

echo "===== Install Python venv ====="
apt install -y python3-venv python3-pip

echo "===== Done ====="

echo "===== Version Information ====="
echo aws --version
echo kubectl version --client
echo eksctl version
echo docker --version
echo helm version
echo java -version
echo python3 --version