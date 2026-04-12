#!/bin/bash
# EKS Node User Data
# This runs on every EKS node at boot time

set -e

# Update system
apt-get update -y
apt-get upgrade -y

# Install CloudWatch agent (optional)
# wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
# dpkg -i -E ./amazon-cloudwatch-agent.deb

echo "EKS Node initialization complete"
