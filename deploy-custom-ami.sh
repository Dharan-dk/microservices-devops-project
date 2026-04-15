#!/bin/bash
# Deploy Custom AMI Jenkins Agent
# Usage: ./deploy-custom-ami.sh <custom-ami-id>

set -e

CUSTOM_AMI_ID="${1:-ami-}"
EIPALLOC_ID="eipalloc-0dfcc84e92cc4f3f1"
ELASTIC_IP="65.2.62.113"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}================================================${NC}"
echo -e "${YELLOW}  CUSTOM AMI JENKINS AGENT DEPLOYMENT${NC}"
echo -e "${YELLOW}================================================${NC}"
echo ""

# Validation
if [[ $CUSTOM_AMI_ID == "ami-" ]]; then
    echo -e "${RED}ERROR: Custom AMI ID not provided${NC}"
    echo "Usage: ./deploy-custom-ami.sh ami-xxxxxxxxxx"
    exit 1
fi

echo -e "${YELLOW}[Step 1] Verifying Custom AMI...${NC}"
AMI_STATE=$(aws ec2 describe-images --image-ids "$CUSTOM_AMI_ID" --query 'Images[0].State' --output text 2>/dev/null || echo "not-found")

if [[ "$AMI_STATE" != "available" ]]; then
    echo -e "${RED}ERROR: AMI $CUSTOM_AMI_ID state is '$AMI_STATE' (expected: available)${NC}"
    echo "Available AMIs in your account:"
    aws ec2 describe-images --owners self --query 'Images[].{ID:ImageId,Name:Name,State:State}' --output table
    exit 1
fi

echo -e "${GREEN}✓ AMI verified: $CUSTOM_AMI_ID (State: $AMI_STATE)${NC}"
echo ""

echo -e "${YELLOW}[Step 2] Verifying Elastic IP...${NC}"
EIP_INFO=$(aws ec2 describe-addresses --allocation-ids "$EIPALLOC_ID" --query 'Addresses[0].[PublicIp,AssociationId]' --output text 2>/dev/null || echo "not-found")

if [[ "$EIP_INFO" == "not-found" ]]; then
    echo -e "${RED}ERROR: Elastic IP allocation $EIPALLOC_ID not found${NC}"
    exit 1
fi

read EIP_ADDR ASSOC_ID <<< "$EIP_INFO"
if [[ -z "$ASSOC_ID" || "$ASSOC_ID" == "None" ]]; then
    echo -e "${GREEN}✓ Elastic IP verified: $ELASTIC_IP (unassociated - ready to attach)${NC}"
else
    echo -e "${YELLOW}⚠ Elastic IP $ELASTIC_IP currently associated (will be reassigned)${NC}"
fi
echo ""

echo -e "${YELLOW}[Step 3] Destroying existing infrastructure...${NC}"
cd terraform

terraform plan -destroy -no-color > /tmp/destroy-plan.txt
DESTROY_LINES=$(grep "will be destroyed" /tmp/destroy-plan.txt | wc -l)
echo "Resources to destroy: $DESTROY_LINES"

read -p "Continue with destroy? (yes/no): " CONFIRM_DESTROY
if [[ "$CONFIRM_DESTROY" != "yes" ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo -e "${YELLOW}Destroying...${NC}"
terraform destroy -auto-approve -no-color
echo -e "${GREEN}✓ Infrastructure destroyed${NC}"
sleep 5
echo ""

echo -e "${YELLOW}[Step 4] Updating Terraform with Custom AMI...${NC}"
# Update main.tf with the custom AMI ID
sed -i "s/custom_ami_id = \"ami-.*\"/custom_ami_id = \"$CUSTOM_AMI_ID\"/" main.tf
echo -e "${GREEN}✓ Updated custom_ami_id to: $CUSTOM_AMI_ID${NC}"
echo ""

echo -e "${YELLOW}[Step 5] Deploying new infrastructure...${NC}"
echo "Applying Terraform config..."
terraform apply -auto-approve -no-color

echo -e "${GREEN}✓ Infrastructure deployed${NC}"
sleep 10
echo ""

echo -e "${YELLOW}[Step 6] Retrieving connection details...${NC}"
INSTANCE_ID=$(terraform output -raw agent_private_ip 2>/dev/null || echo "pending")
AGENT_EIP=$(aws ec2 describe-addresses --allocation-ids "$EIPALLOC_ID" --query 'Addresses[0].PublicIp' --output text)

echo -e "${GREEN}Connection Details:${NC}"
echo "  Elastic IP: $AGENT_EIP ($ELASTIC_IP)"
echo "  SSH Command: ssh -i ~/Root_EKS.pem ubuntu@$AGENT_EIP"
echo ""

echo -e "${YELLOW}[Step 7] Waiting for instance boot (~2-3 minutes)...${NC}"
INSTANCE_STATE="pending"
WAIT_ITERATIONS=0
MAX_ITERATIONS=60

while [[ "$INSTANCE_STATE" != "running" && $WAIT_ITERATIONS -lt $MAX_ITERATIONS ]]; do
    INSTANCE_ID=$(aws ec2 describe-instances \
        --filters "Name=tag:Environment,Values=dev" "Name=tag:Project,Values=cloudmart" \
        --query 'Reservations[0].Instances[0].InstanceId' --output text)
    
    if [[ ! -z "$INSTANCE_ID" && "$INSTANCE_ID" != "None" ]]; then
        INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
            --query 'Reservations[0].Instances[0].State.Name' --output text)
        echo "  Instance state: $INSTANCE_STATE"
    fi
    
    if [[ "$INSTANCE_STATE" != "running" ]]; then
        sleep 3
    fi
    ((WAIT_ITERATIONS++))
done

if [[ "$INSTANCE_STATE" == "running" ]]; then
    echo -e "${GREEN}✓ Instance is running${NC}"
else
    echo -e "${RED}✗ Instance failed to start after 3 minutes${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}[Step 8] Verifying tool installation...${NC}"
for i in {1..10}; do
    if ssh -i ~/Root_EKS.pem -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@$AGENT_EIP "java -version" &>/dev/null; then
        echo -e "${GREEN}✓ Tools verified (SSH connection successful)${NC}"
        break
    fi
    if [[ $i -lt 10 ]]; then
        echo "  Waiting for SSH to be ready... ($i/10)"
        sleep 5
    fi
done
echo ""

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  DEPLOYMENT COMPLETE!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${GREEN}Jenkins Static Agent Ready:${NC}"
echo "  • IP Address: $AGENT_EIP"
echo "  • Instance Type: c7i-flex.large"
echo "  • Custom AMI: $CUSTOM_AMI_ID"
echo "  • Pre-installed: Java 17, Docker, AWS CLI, Trivy, SonarScanner"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Test SSH: ssh -i ~/Root_EKS.pem ubuntu@$AGENT_EIP"
echo "  2. Verify tools:"
echo "     - java -version"
echo "     - docker --version"
echo "     - aws --version"
echo "     - trivy --version"
echo "     - sonar-scanner --version"
echo "  3. Register agent in Jenkins with IP: $AGENT_EIP:22"
echo ""
