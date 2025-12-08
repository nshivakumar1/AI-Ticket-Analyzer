#!/bin/bash

# Script to help gather values for GitHub Secrets
# Run this after terraform apply to get all required values

echo "=========================================="
echo "GitHub Secrets Value Helper"
echo "=========================================="
echo ""

# Check if terraform outputs exist
if [ ! -f "terraform/outputs.tf" ]; then
    echo "❌ Error: terraform directory not found"
    echo "Run this from the project root directory"
    exit 1
fi

cd terraform 2>/dev/null || {
    echo "❌ Error: Could not access terraform directory"
    exit 1
}

echo "📋 Gathering values from Terraform outputs..."
echo ""

# AWS Account ID
echo "1️⃣  AWS_ACCOUNT_ID:"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
if [ -n "$AWS_ACCOUNT_ID" ]; then
    echo "   ✅ $AWS_ACCOUNT_ID"
else
    echo "   ⚠️  Run: aws sts get-caller-identity --query Account --output text"
fi
echo ""

# EC2 Public IP
echo "2️⃣  EC2_HOST:"
EC2_IP=$(terraform output -raw ec2_public_ip 2>/dev/null)
if [ -n "$EC2_IP" ]; then
    echo "   ✅ $EC2_IP"
else
    echo "   ⚠️  Run terraform apply first, then: terraform output ec2_public_ip"
fi
echo ""

# DynamoDB Table Name
echo "3️⃣  DYNAMODB_TABLE_NAME:"
DYNAMO_TABLE=$(terraform output -raw dynamodb_table_name 2>/dev/null)
if [ -n "$DYNAMO_TABLE" ]; then
    echo "   ✅ $DYNAMO_TABLE"
else
    echo "   ⚠️  Run terraform apply first, then: terraform output dynamodb_table_name"
fi
echo ""

# S3 Bucket Name
echo "4️⃣  S3_BUCKET_NAME:"
S3_BUCKET=$(terraform output -raw s3_bucket_name 2>/dev/null)
if [ -n "$S3_BUCKET" ]; then
    echo "   ✅ $S3_BUCKET"
else
    echo "   ⚠️  Run terraform apply first, then: terraform output s3_bucket_name"
fi
echo ""

# CloudFront Distribution ID
echo "5️⃣  CLOUDFRONT_DISTRIBUTION_ID:"
CF_ID=$(terraform output -raw cloudfront_distribution_id 2>/dev/null)
if [ -n "$CF_ID" ] && [ "$CF_ID" != "null" ]; then
    echo "   ✅ $CF_ID"
else
    echo "   ⚠️  Run terraform apply first, then: terraform output cloudfront_distribution_id"
fi
echo ""

# API Base URL
echo "6️⃣  API_BASE_URL:"
if [ -n "$EC2_IP" ]; then
    echo "   ✅ http://$EC2_IP"
else
    echo "   ⚠️  http://YOUR_EC2_IP (use EC2_HOST value)"
fi
echo ""

echo "=========================================="
echo "📝 Manual Steps Required:"
echo "=========================================="
echo ""
echo "7️⃣  AWS_ACCESS_KEY_ID:"
echo "   → AWS Console → IAM → Users → Create user → Access keys"
echo ""
echo "8️⃣  AWS_SECRET_ACCESS_KEY:"
echo "   → Same as above (save immediately - only shown once!)"
echo ""
echo "9️⃣  EC2_SSH_KEY:"
echo "   → Run: cat ~/.ssh/id_rsa"
echo "   → Copy the ENTIRE output including BEGIN/END lines"
echo ""

echo "=========================================="
echo "✅ Next Steps:"
echo "=========================================="
echo "1. Copy the values above"
echo "2. Go to: GitHub Repo → Settings → Secrets → Actions"
echo "3. Add each secret one by one"
echo "4. See SECRETS_CHECKLIST.md for full list"
echo ""

