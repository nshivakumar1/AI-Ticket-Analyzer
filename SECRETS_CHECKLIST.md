# GitHub Secrets Setup Checklist

Use this checklist to ensure all secrets are configured correctly.

## 🔐 Secrets to Configure

### Required for Backend Workflow

- [ ] **AWS_ACCESS_KEY_ID**
  - Get from: AWS IAM → Create user → Access keys
  - Value: `AKIA...` (20 characters)

- [ ] **AWS_SECRET_ACCESS_KEY**
  - Get from: Same as above (only shown once!)
  - Value: `wJalr...` (40 characters)

- [ ] **AWS_ACCOUNT_ID**
  - Get from: `aws sts get-caller-identity` or AWS Console top-right
  - Value: `123456789012` (12 digits)

- [ ] **EC2_HOST**
  - Get from: `terraform output ec2_public_ip` (after terraform apply)
  - Value: `54.123.45.67` or DNS name

- [ ] **EC2_SSH_KEY**
  - Get from: `cat ~/.ssh/id_rsa` (your private key)
  - Value: Full key including `-----BEGIN RSA PRIVATE KEY-----`

- [ ] **DYNAMODB_TABLE_NAME**
  - Get from: `terraform output dynamodb_table_name`
  - Value: `ticket-analyzer-dev-tickets`

### Required for Frontend Workflow

- [ ] **API_BASE_URL**
  - Get from: Your EC2 public IP (same as EC2_HOST)
  - Value: `http://54.123.45.67`

- [ ] **S3_BUCKET_NAME**
  - Get from: `terraform output s3_bucket_name`
  - Value: `ticket-analyzer-dev-frontend-xxxx`

- [ ] **CLOUDFRONT_DISTRIBUTION_ID** (Optional but recommended)
  - Get from: `terraform output cloudfront_distribution_id`
  - Value: `E1234567890ABC`

## 📍 Where to Add Secrets

1. Go to: **Your GitHub Repo** → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Add each secret one by one

## ⚠️ Important

- Secrets are case-sensitive
- `EC2_SSH_KEY` must include the full key with headers
- `AWS_SECRET_ACCESS_KEY` can only be viewed once - save it!
- Update `API_BASE_URL` after backend is deployed

## 🚀 Quick Commands

```bash
# Get AWS Account ID
aws sts get-caller-identity --query Account --output text

# Get Terraform outputs (after terraform apply)
cd terraform
terraform output

# Get EC2 IP
terraform output ec2_public_ip

# Get DynamoDB table name
terraform output dynamodb_table_name

# Get S3 bucket name
terraform output s3_bucket_name

# Get CloudFront ID
terraform output cloudfront_distribution_id
```

## ✅ Verification

After adding all secrets:
1. Go to Settings → Secrets and variables → Actions
2. Verify all 9 secrets are listed
3. They should all show as `••••••••`

---

**Total Secrets Needed: 9**
- 6 for Backend
- 3 for Frontend

