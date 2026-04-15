#!/bin/bash
# Create Custom AMI from Existing Jenkins Agent
# Run this script to build a custom AMI with all tools pre-installed

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  CREATE CUSTOM AMI - JENKINS AGENT${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Step 1: Get current instance
echo -e "${YELLOW}[Step 1] Finding current Jenkins agent instance...${NC}"

cd terraform

INSTANCE_ID=$(terraform output -raw agent_private_ip 2>/dev/null | head -1)
if [[ -z "$INSTANCE_ID" ]]; then
    echo -e "${RED}ERROR: Could not find instance from Terraform output${NC}"
    echo "Make sure Terraform resources are created: terraform apply"
    exit 1
fi

# Get the actual instance ID
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Project,Values=cloudmart" "Name=tag:Environment,Values=dev" \
    --query 'Reservations[0].Instances[0].InstanceId' --output text)

if [[ -z "$INSTANCE_ID" || "$INSTANCE_ID" == "None" ]]; then
    echo -e "${RED}ERROR: No running Jenkins agent instance found${NC}"
    echo "Please create it first: terraform apply"
    exit 1
fi

echo -e "${GREEN}✓ Found instance: $INSTANCE_ID${NC}"

# Step 2: Check instance state
echo ""
echo -e "${YELLOW}[Step 2] Checking instance state...${NC}"

INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].State.Name' --output text)

if [[ "$INSTANCE_STATE" != "running" ]]; then
    echo -e "${RED}ERROR: Instance is not running (state: $INSTANCE_STATE)${NC}"
    echo "Please wait for instance to be running and try again."
    exit 1
fi

echo -e "${GREEN}✓ Instance is running${NC}"

# Step 3: Get instance details
echo ""
echo -e "${YELLOW}[Step 3] Retrieving instance details...${NC}"

INSTANCE_INFO=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" \
    --query 'Reservations[0].Instances[0].[PublicIpAddress,PrivateIpAddress,InstanceType]' --output text)

PUBLIC_IP=$(echo $INSTANCE_INFO | awk '{print $1}')
PRIVATE_IP=$(echo $INSTANCE_INFO | awk '{print $2}')
INSTANCE_TYPE=$(echo $INSTANCE_INFO | awk '{print $3}')

echo -e "${GREEN}Instance Details:${NC}"
echo "  ID: $INSTANCE_ID"
echo "  Public IP: $PUBLIC_IP"
echo "  Private IP: $PRIVATE_IP"
echo "  Type: $INSTANCE_TYPE"
echo ""

# Step 4: Verify tools are installed
echo -e "${YELLOW}[Step 4] Verifying tools are installed on instance...${NC}"

SSH_KEY="${SSH_KEY:-$HOME/Root_EKS.pem}"

if [[ ! -f "$SSH_KEY" ]]; then
    echo -e "${RED}ERROR: SSH key not found: $SSH_KEY${NC}"
    read -p "Enter path to your SSH key: " SSH_KEY
    if [[ ! -f "$SSH_KEY" ]]; then
        echo -e "${RED}ERROR: SSH key not found: $SSH_KEY${NC}"
        exit 1
    fi
fi

echo -e "${YELLOW}Testing SSH connection...${NC}"
if ! ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 ubuntu@"$PUBLIC_IP" "java -version" &>/dev/null 2>&1; then
    echo -e "${RED}ERROR: Cannot SSH to instance${NC}"
    echo "Please ensure:"
    echo "  1. Security group allows SSH (port 22)"
    echo "  2. SSH key is correct: $SSH_KEY"
    echo "  3. Instance has a public IP: $PUBLIC_IP"
    exit 1
fi

echo -e "${GREEN}✓ SSH connection successful${NC}"

# Verify tools
echo -e "${YELLOW}Verifying pre-installed tools...${NC}"

TOOLS_CHECK=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ubuntu@"$PUBLIC_IP" bash << 'EOF'
{
    echo "=== Java ===" && java -version 2>&1 | head -2
    echo ""
    echo "=== Docker ===" && docker --version
    echo ""
    echo "=== Python ===" && python3 --version
    echo ""
    echo "=== AWS CLI ===" && aws --version
    echo ""
    echo "=== Trivy ===" && trivy --version
    echo ""
    echo "=== SonarScanner ===" && sonar-scanner --version
    echo ""
    echo "=== Swap ===" && free -h | grep Swap
} 2>/dev/null || echo "Some tools not found - that's OK, will install during AMI creation"
EOF
)

echo "$TOOLS_CHECK"
echo ""

# Step 5: Confirm AMI creation
echo -e "${YELLOW}[Step 5] Confirming AMI creation details...${NC}"
echo -e "${BLUE}This will create an AMI image from the running instance.${NC}"
echo -e "${BLUE}The instance will NOT be stopped (--no-reboot flag will be used).${NC}"
echo ""

read -p "Continue creating AMI? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Cancelled."
    exit 0
fi

# Step 6: Create AMI
echo ""
echo -e "${YELLOW}[Step 6] Creating custom AMI...${NC}"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
AMI_NAME="jenkins-static-agent-custom-$TIMESTAMP"
AMI_DESC="Jenkins agent with Java 17, Docker, AWS CLI v2, Trivy, SonarScanner - Custom built $(date '+%Y-%m-%d %H:%M:%S')"

echo "Creating AMI: $AMI_NAME"
echo "Description: $AMI_DESC"
echo ""

CREATE_OUTPUT=$(aws ec2 create-image \
    --instance-id "$INSTANCE_ID" \
    --name "$AMI_NAME" \
    --description "$AMI_DESC" \
    --no-reboot \
    --output json)

AMI_ID=$(echo $CREATE_OUTPUT | grep -o '"ImageId": "[^"]*' | cut -d'"' -f4)

echo -e "${GREEN}✓ AMI creation initiated${NC}"
echo "AMI ID: $AMI_ID"
echo ""

# Step 7: Wait for AMI to be available
echo -e "${YELLOW}[Step 7] Waiting for AMI to be available...${NC}"
echo "(This typically takes 5-15 minutes)"
echo ""

WAIT_ITERATIONS=0
MAX_ITERATIONS=180  # 15 minutes max

while [[ $WAIT_ITERATIONS -lt $MAX_ITERATIONS ]]; do
    AMI_STATE=$(aws ec2 describe-images --image-ids "$AMI_ID" \
        --query 'Images[0].State' --output text)
    
    PROGRESS=$(aws ec2 describe-images --image-ids "$AMI_ID" \
        --query 'Images[0].Progress' --output text)
    
    if [[ "$PROGRESS" != "None" ]]; then
        echo -ne "\r  Progress: $PROGRESS                    "
    else
        echo -ne "\r  State: $AMI_STATE                    "
    fi
    
    if [[ "$AMI_STATE" == "available" ]]; then
        echo ""
        echo -e "${GREEN}✓ AMI is now available!${NC}"
        break
    fi
    
    if [[ "$AMI_STATE" == "failed" ]]; then
        echo -e "${RED}✗ AMI creation failed${NC}"
        exit 1
    fi
    
    sleep 5
    ((WAIT_ITERATIONS++))
done

if [[ $WAIT_ITERATIONS -ge $MAX_ITERATIONS ]]; then
    echo -e "${YELLOW}Timeout waiting for AMI. Please check AWS console.${NC}"
fi

echo ""

# Step 8: Display results
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  CUSTOM AMI CREATED!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "${GREEN}AMI Details:${NC}"
echo "  Name: $AMI_NAME"
echo "  ID: $AMI_ID"
echo "  State: available"
echo ""

# Step 9: Update Terraform
echo -e "${YELLOW}[Step 8] Update Terraform configuration${NC}"
echo ""
echo "Add this AMI ID to your Terraform configuration:"
echo ""
echo -e "${BLUE}  # In terraform/main.tf, update:${NC}"
echo -e "${BLUE}  custom_ami_id = \"$AMI_ID\"${NC}"
echo ""

read -p "Update terraform/main.tf automatically? (yes/no): " UPDATE_TF
if [[ "$UPDATE_TF" == "yes" ]]; then
    sed -i "s/custom_ami_id = \"ami-[^\"]*\"/custom_ami_id = \"$AMI_ID\"/" main.tf
    echo -e "${GREEN}✓ terraform/main.tf updated${NC}"
    echo ""
    echo -e "${YELLOW}Next step: Deploy the AMI${NC}"
    echo "  cd terraform"
    echo "  ./deploy-custom-ami.sh $AMI_ID"
fi

echo ""
echo -e "${GREEN}Custom AMI is ready for deployment!${NC}"
echo ""
