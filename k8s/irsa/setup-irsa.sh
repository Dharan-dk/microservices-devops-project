#!/bin/bash
# =============================================================================
# setup-irsa.sh — One-time IRSA setup for AWS Load Balancer Controller
#
# Run this ONCE manually before your first Jenkins pipeline run.
# After this, Jenkins + Helm handle everything automatically.
#
# Usage:
#   chmod +x k8s/irsa/setup-irsa.sh
#   ./k8s/irsa/setup-irsa.sh
# =============================================================================

set -e  # exit immediately on any error

# ── CONFIG — fill these in before running ─────────────────────────────────────
AWS_ACCOUNT_ID="204844252943"
AWS_REGION="ap-south-1"
EKS_CLUSTER_NAME="cloudmart-eks-cluster"
IAM_ROLE_NAME="AmazonEKSLoadBalancerControllerRole"
IAM_POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"
# ──────────────────────────────────────────────────────────────────────────────

echo "=============================================="
echo " CloudMart IRSA Setup"
echo " Cluster : $EKS_CLUSTER_NAME"
echo " Region  : $AWS_REGION"
echo " Account : $AWS_ACCOUNT_ID"
echo "=============================================="

# ── Step 1: Get OIDC Provider ID from EKS cluster ─────────────────────────────
echo ""
echo "[1/4] Fetching OIDC provider URL from EKS..."

OIDC_URL=$(aws eks describe-cluster \
    --name "$EKS_CLUSTER_NAME" \
    --region "$AWS_REGION" \
    --query "cluster.identity.oidc.issuer" \
    --output text)

# Extract just the ID part (last segment of URL)
# e.g. https://oidc.eks.ap-south-1.amazonaws.com/id/ABCD1234 → ABCD1234
OIDC_ID=$(echo "$OIDC_URL" | awk -F'/' '{print $NF}')

echo "    OIDC URL : $OIDC_URL"
echo "    OIDC ID  : $OIDC_ID"

# ── Step 2: Register OIDC provider in IAM (if not already done) ───────────────
echo ""
echo "[2/4] Associating OIDC provider with IAM..."

# Check if already exists
EXISTING=$(aws iam list-open-id-connect-providers \
    --query "OpenIDConnectProviderList[?contains(Arn, '$OIDC_ID')].Arn" \
    --output text)

if [ -z "$EXISTING" ]; then
    # eksctl does this cleanly — install if not present: 
    # https://eksctl.io/installation/
    eksctl utils associate-iam-oidc-provider \
        --cluster "$EKS_CLUSTER_NAME" \
        --region "$AWS_REGION" \
        --approve
    echo "    OIDC provider registered."
else
    echo "    OIDC provider already exists — skipping."
fi

# ── Step 3: Create IAM Policy from alb-controller-policy.json ─────────────────
echo ""
echo "[3/4] Creating IAM policy '$IAM_POLICY_NAME'..."

# Check if policy already exists
POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${IAM_POLICY_NAME}"
EXISTING_POLICY=$(aws iam list-policies \
    --query "Policies[?PolicyName=='$IAM_POLICY_NAME'].Arn" \
    --output text)

if [ -z "$EXISTING_POLICY" ]; then
    aws iam create-policy \
        --policy-name "$IAM_POLICY_NAME" \
        --policy-document file://k8s/irsa/alb-controller-policy.json \
        --region "$AWS_REGION"
    echo "    IAM policy created: $POLICY_ARN"
else
    echo "    IAM policy already exists — skipping."
    POLICY_ARN="$EXISTING_POLICY"
fi

# ── Step 4: Create IAM Role with trust policy ─────────────────────────────────
echo ""
echo "[4/4] Creating IAM role '$IAM_ROLE_NAME'..."

# Substitute real values into trust-policy.json
sed \
    -e "s/ACCOUNT_ID/$AWS_ACCOUNT_ID/g" \
    -e "s/REGION/$AWS_REGION/g" \
    -e "s/OIDC_ID/$OIDC_ID/g" \
    k8s/irsa/trust-policy.json > /tmp/trust-policy-resolved.json

echo "    Trust policy (resolved):"
cat /tmp/trust-policy-resolved.json

# Check if role already exists
EXISTING_ROLE=$(aws iam list-roles \
    --query "Roles[?RoleName=='$IAM_ROLE_NAME'].RoleName" \
    --output text)

if [ -z "$EXISTING_ROLE" ]; then
    aws iam create-role \
        --role-name "$IAM_ROLE_NAME" \
        --assume-role-policy-document file:///tmp/trust-policy-resolved.json

    echo "    IAM role created."
else
    echo "    IAM role already exists — skipping creation."
fi

# Attach the ALB policy to the role (idempotent)
aws iam attach-role-policy \
    --role-name "$IAM_ROLE_NAME" \
    --policy-arn "$POLICY_ARN"

echo "    Policy attached to role."

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo "=============================================="
echo " IRSA Setup Complete!"
echo "=============================================="
echo ""
echo " IAM Role ARN:"
echo " arn:aws:iam::${AWS_ACCOUNT_ID}:role/${IAM_ROLE_NAME}"
echo ""
echo " Next steps:"
echo " 1. Copy the Role ARN above"
echo " 2. Paste it into k8s/alb-ingress/service-account.yaml"
echo "    under: eks.amazonaws.com/role-arn"
echo " 3. Push to GitHub — Jenkins handles the rest!"
echo "=============================================="

#!/bin/bash
set -euo pipefail

# ================= CONFIG =================
AWS_ACCOUNT_ID="204844252943"
AWS_REGION="ap-south-1"
EKS_CLUSTER_NAME="cloudmart-eks-cluster"
IAM_ROLE_NAME="AmazonEKSLoadBalancerControllerRole"
IAM_POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"
POLICY_FILE="k8s/irsa/alb-controller-policy.json"
TRUST_TEMPLATE="k8s/irsa/trust-policy.json"
# ==========================================

echo "=============================================="
echo " CloudMart IRSA Setup (FIXED)"
echo "=============================================="

# ── Step 1: Get OIDC URL ───────────────────
echo "[1/5] Getting OIDC provider from EKS..."

OIDC_URL=$(aws eks describe-cluster \
  --name "$EKS_CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --query "cluster.identity.oidc.issuer" \
  --output text)

OIDC_ID=$(echo "$OIDC_URL" | awk -F'/' '{print $NF}')

echo "OIDC URL : $OIDC_URL"
echo "OIDC ID  : $OIDC_ID"

# ── Step 2: Ensure OIDC exists (NO eksctl) ─
echo "[2/5] Ensuring OIDC provider exists..."

OIDC_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/oidc.eks.${AWS_REGION}.amazonaws.com/id/${OIDC_ID}"

if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "$OIDC_ARN" >/dev/null 2>&1; then
  echo "OIDC already exists"
else
  echo "Creating OIDC provider..."

  THUMBPRINT=$(echo | openssl s_client -servername oidc.eks.${AWS_REGION}.amazonaws.com \
    -connect oidc.eks.${AWS_REGION}.amazonaws.com:443 2>/dev/null \
    | openssl x509 -fingerprint -noout \
    | sed 's/.*=//' | sed 's/://g')

  aws iam create-open-id-connect-provider \
    --url "$OIDC_URL" \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list "$THUMBPRINT"

  echo "OIDC created"
fi

# ── Step 3: Create / reuse IAM Policy ──────
echo "[3/5] Ensuring IAM policy..."

POLICY_ARN=$(aws iam list-policies \
  --query "Policies[?PolicyName=='$IAM_POLICY_NAME'].Arn" \
  --output text)

if [ -z "$POLICY_ARN" ]; then
  POLICY_ARN=$(aws iam create-policy \
    --policy-name "$IAM_POLICY_NAME" \
    --policy-document file://$POLICY_FILE \
    --query 'Policy.Arn' \
    --output text)

  echo "Policy created: $POLICY_ARN"
else
  echo "Policy exists: $POLICY_ARN"
fi

# ── Step 4: Create / update IAM Role ───────
echo "[4/5] Ensuring IAM role..."

sed \
  -e "s/ACCOUNT_ID/$AWS_ACCOUNT_ID/g" \
  -e "s/REGION/$AWS_REGION/g" \
  -e "s/OIDC_ID/$OIDC_ID/g" \
  $TRUST_TEMPLATE > /tmp/trust.json

if aws iam get-role --role-name "$IAM_ROLE_NAME" >/dev/null 2>&1; then
  echo "Role exists → updating trust policy"
  aws iam update-assume-role-policy \
    --role-name "$IAM_ROLE_NAME" \
    --policy-document file:///tmp/trust.json
else
  echo "Creating IAM role"
  aws iam create-role \
    --role-name "$IAM_ROLE_NAME" \
    --assume-role-policy-document file:///tmp/trust.json
fi

# ── Step 5: Attach policy (idempotent) ─────
echo "[5/5] Attaching policy to role..."

aws iam attach-role-policy \
  --role-name "$IAM_ROLE_NAME" \
  --policy-arn "$POLICY_ARN" || true

echo ""
echo "=============================================="
echo " IRSA READY"
echo "=============================================="

ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${IAM_ROLE_NAME}"
echo "Role ARN:"
echo "$ROLE_ARN"

echo ""
echo "👉 Next:"
echo "kubectl annotate sa aws-load-balancer-controller -n kube-system \\"
echo "  eks.amazonaws.com/role-arn=$ROLE_ARN --overwrite"