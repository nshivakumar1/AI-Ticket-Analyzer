# GitHub Secrets Configuration Guide

This guide will walk you through setting up all required GitHub Secrets for CI/CD deployment.

## 📍 Step 1: Navigate to GitHub Secrets

1. Go to your GitHub repository
2. Click on **Settings** (top menu)
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret** button

## 🔑 Required Secrets

### Backend Workflow Secrets

#### 1. `AWS_ACCESS_KEY_ID`
**Purpose**: AWS access key for authentication  
**How to get it**:
```bash
# Option 1: If you already have AWS CLI configured
aws configure get aws_access_key_id

# Option 2: Create new IAM user
# 1. Go to AWS Console → IAM → Users
# 2. Click "Add users"
# 3. Username: github-actions
# 4. Select "Programmatic access"
# 5. Attach policy: PowerUserAccess (or create custom policy)
# 6. Copy Access Key ID
```
**Example**: `AKIAIOSFODNN7EXAMPLE`

#### 2. `AWS_SECRET_ACCESS_KEY`
**Purpose**: AWS secret key (paired with access key)  
**How to get it**: Same as above - copy the Secret Access Key when creating IAM user  
**⚠️ Important**: Save this immediately - you can only see it once!  
**Example**: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`

#### 3. `AWS_ACCOUNT_ID`
**Purpose**: Your AWS account ID (12 digits)  
**How to get it**:
```bash
# Via AWS CLI
aws sts get-caller-identity --query Account --output text

# Or in AWS Console
# Top right corner → Click on your account name → Account ID
```
**Example**: `123456789012`

#### 4. `EC2_HOST`
**Purpose**: EC2 instance public IP or DNS name  
**How to get it**:
```bash
# After running terraform apply
terraform output ec2_public_ip
# OR
terraform output ec2_public_dns

# Or in AWS Console
# EC2 → Instances → Select your instance → Copy Public IPv4 address
```
**Example**: `54.123.45.67` or `ec2-54-123-45-67.compute-1.amazonaws.com`

#### 5. `EC2_SSH_KEY`
**Purpose**: Private SSH key for EC2 access  
**How to get it**:
```bash
# If you used an existing key pair
cat ~/.ssh/id_rsa

# Copy the entire output including:
# -----BEGIN RSA PRIVATE KEY-----
# ... (all lines) ...
# -----END RSA PRIVATE KEY-----

# ⚠️ Make sure to copy the ENTIRE key including headers
```
**Example**: 
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
(multiple lines)
...
-----END RSA PRIVATE KEY-----
```

#### 6. `DYNAMODB_TABLE_NAME`
**Purpose**: DynamoDB table name for tickets  
**How to get it**:
```bash
# After terraform apply
terraform output dynamodb_table_name

# Or in AWS Console
# DynamoDB → Tables → Copy table name
```
**Example**: `ticket-analyzer-dev-tickets`

### Frontend Workflow Secrets

#### 7. `API_BASE_URL`
**Purpose**: Backend API URL for frontend build  
**How to get it**:
```bash
# After EC2 is running and backend is deployed
# Use your EC2 public IP or DNS
```
**Example**: `http://54.123.45.67` or `http://ec2-54-123-45-67.compute-1.amazonaws.com`

#### 8. `S3_BUCKET_NAME`
**Purpose**: S3 bucket name for frontend deployment  
**How to get it**:
```bash
# After terraform apply
terraform output s3_bucket_name

# Or in AWS Console
# S3 → Buckets → Copy bucket name
```
**Example**: `ticket-analyzer-dev-frontend-a1b2c3d4`

#### 9. `CLOUDFRONT_DISTRIBUTION_ID` (Optional)
**Purpose**: CloudFront distribution ID for cache invalidation  
**How to get it**:
```bash
# After terraform apply
terraform output cloudfront_distribution_id

# Or in AWS Console
# CloudFront → Distributions → Copy Distribution ID
```
**Example**: `E1234567890ABC`

## 📝 Step-by-Step Setup

### Quick Setup (If Infrastructure Already Deployed)

1. **Get Terraform Outputs**:
   ```bash
   cd terraform
   terraform output -json > ../terraform-outputs.json
   ```

2. **Extract Values**:
   ```bash
   # View outputs
   cat terraform-outputs.json
   ```

3. **Add Secrets to GitHub** (repeat for each):
   - Go to: Repository → Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `AWS_ACCESS_KEY_ID`
   - Value: (paste your value)
   - Click "Add secret"

### Detailed Setup

#### Secret 1: AWS_ACCESS_KEY_ID
1. Click **New repository secret**
2. Name: `AWS_ACCESS_KEY_ID`
3. Secret: Paste your AWS Access Key ID
4. Click **Add secret**

#### Secret 2: AWS_SECRET_ACCESS_KEY
1. Click **New repository secret**
2. Name: `AWS_SECRET_ACCESS_KEY`
3. Secret: Paste your AWS Secret Access Key
4. Click **Add secret**

#### Secret 3: AWS_ACCOUNT_ID
1. Click **New repository secret**
2. Name: `AWS_ACCOUNT_ID`
3. Secret: Paste your 12-digit AWS Account ID
4. Click **Add secret**

#### Secret 4: EC2_HOST
1. Click **New repository secret**
2. Name: `EC2_HOST`
3. Secret: Paste your EC2 public IP or DNS
4. Click **Add secret**

#### Secret 5: EC2_SSH_KEY
1. Click **New repository secret**
2. Name: `EC2_SSH_KEY`
3. Secret: Paste your **ENTIRE** private SSH key (including BEGIN/END lines)
4. Click **Add secret**

#### Secret 6: DYNAMODB_TABLE_NAME
1. Click **New repository secret**
2. Name: `DYNAMODB_TABLE_NAME`
3. Secret: Paste your DynamoDB table name
4. Click **Add secret**

#### Secret 7: API_BASE_URL
1. Click **New repository secret**
2. Name: `API_BASE_URL`
3. Secret: `http://YOUR_EC2_IP` (replace with your actual IP)
4. Click **Add secret**

#### Secret 8: S3_BUCKET_NAME
1. Click **New repository secret**
2. Name: `S3_BUCKET_NAME`
3. Secret: Paste your S3 bucket name
4. Click **Add secret**

#### Secret 9: CLOUDFRONT_DISTRIBUTION_ID (Optional)
1. Click **New repository secret**
2. Name: `CLOUDFRONT_DISTRIBUTION_ID`
3. Secret: Paste your CloudFront distribution ID
4. Click **Add secret**

## ✅ Verification

After adding all secrets, verify they're set:

1. Go to: Repository → Settings → Secrets and variables → Actions
2. You should see all 9 secrets listed
3. Secrets are masked (shown as `••••••••`)

## 🚨 Important Notes

### Security Best Practices

1. **Never commit secrets to code**
   - ✅ Use GitHub Secrets
   - ❌ Don't put in `.env` files that are committed
   - ❌ Don't hardcode in source files

2. **IAM User Permissions**
   - Create a dedicated IAM user for GitHub Actions
   - Use least privilege principle
   - Attach only necessary policies:
     - `AmazonEC2FullAccess` (or custom policy)
     - `AmazonS3FullAccess` (or custom policy)
     - `AmazonDynamoDBFullAccess` (or custom policy)
     - `AmazonEC2ContainerRegistryFullAccess`
     - `CloudFrontFullAccess`
     - `AmazonSSMReadOnlyAccess` (for parameter store)

3. **SSH Key Security**
   - Use a dedicated SSH key for deployments
   - Don't use your personal SSH key
   - Rotate keys regularly

### If Infrastructure Not Deployed Yet

If you haven't run `terraform apply` yet, you'll need to:

1. **Deploy infrastructure first**:
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

2. **Then get the outputs** and set secrets as described above

3. **Alternative**: You can set placeholder values and update them later:
   - `EC2_HOST`: `placeholder` (update after EC2 is created)
   - `S3_BUCKET_NAME`: `placeholder` (update after S3 is created)
   - etc.

## 🔧 Troubleshooting

### Secret not found error
- Verify secret name matches exactly (case-sensitive)
- Check you're in the correct repository
- Ensure secret was added to Actions secrets (not Dependabot)

### SSH connection failed
- Verify `EC2_HOST` is correct (IP or DNS)
- Check `EC2_SSH_KEY` includes full key with headers
- Ensure EC2 security group allows SSH (port 22) from GitHub IPs
- Test SSH manually: `ssh -i ~/.ssh/id_rsa ec2-user@YOUR_EC2_IP`

### AWS authentication failed
- Verify `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are correct
- Check IAM user has necessary permissions
- Verify `AWS_ACCOUNT_ID` matches your account

## 📋 Checklist

Before running CI/CD, ensure:

- [ ] All 9 secrets are added
- [ ] AWS credentials are valid
- [ ] EC2 instance is running
- [ ] DynamoDB table exists
- [ ] S3 bucket exists
- [ ] ECR repository exists (created by terraform)
- [ ] SSH key has correct permissions
- [ ] Security groups allow necessary traffic

## 🎯 Next Steps

After configuring secrets:

1. **Test Backend Workflow**:
   - Make a small change to `backend/` directory
   - Push to `main` branch
   - Check Actions tab for workflow run

2. **Test Frontend Workflow**:
   - Make a small change to `frontend/` directory
   - Push to `main` branch
   - Check Actions tab for workflow run

3. **Monitor Deployments**:
   - Watch workflow logs in Actions tab
   - Verify deployment success
   - Test the deployed application

---

**Need help?** Check the workflow logs in GitHub Actions tab for detailed error messages.

