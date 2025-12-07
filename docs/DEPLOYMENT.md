# Deployment Guide

Complete guide for deploying the AI Support Ticket Analyzer to AWS.

## Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.5.0
- AWS CLI configured
- Docker installed locally
- GitHub account (for CI/CD)
- OpenAI API key
- SSH key pair for EC2 access

## Step 1: Infrastructure Setup

### 1.1 Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
aws_region         = "us-east-1"
project_name       = "ticket-analyzer"
environment        = "dev"
ec2_instance_type  = "t2.micro"
openai_api_key     = "sk-your-openai-key"
dynamodb_table_name = "tickets"
ecr_repository_name = "ticket-analyzer-backend"
enable_cloudfront  = true
```

### 1.2 Update SSH Key Path

Edit `terraform/main.tf` and update the key pair path:

```hcl
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = file("~/.ssh/id_rsa.pub")  # Update this path
  ...
}
```

### 1.3 Initialize and Apply Terraform

```bash
terraform init
terraform plan
terraform apply
```

This will create:
- EC2 instance (t2.micro)
- DynamoDB table
- S3 bucket for frontend
- CloudFront distribution
- ECR repository
- IAM roles and policies
- Security groups

### 1.4 Save Outputs

After terraform apply completes, save the outputs:

```bash
terraform output -json > terraform-outputs.json
```

Note down:
- EC2 instance ID and public IP
- S3 bucket name
- CloudFront distribution ID
- ECR repository URL
- DynamoDB table name

## Step 2: EC2 Setup

### 2.1 SSH into EC2 Instance

```bash
ssh -i ~/.ssh/id_rsa ec2-user@<EC2_PUBLIC_IP>
```

### 2.2 Run Setup Script

```bash
# Copy setup script to EC2 or run commands manually
./scripts/setup-ec2.sh
```

Or manually:

```bash
# Install Docker
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Nginx
sudo yum install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 2.3 Configure Nginx

Create `/etc/nginx/conf.d/ticket-analyzer.conf`:

```nginx
upstream backend {
    server localhost:8000;
}

server {
    listen 80;
    server_name _;

    location /api/ {
        proxy_pass http://backend/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Test and reload:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

## Step 3: Backend Deployment

### 3.1 Build and Push Docker Image

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Build image
cd backend
docker build -t ticket-analyzer-backend:latest .

# Tag for ECR
docker tag ticket-analyzer-backend:latest <ECR_REPO_URL>:latest

# Push to ECR
docker push <ECR_REPO_URL>:latest
```

### 3.2 Deploy to EC2

SSH into EC2 and run:

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Pull image
docker pull <ECR_REPO_URL>:latest

# Get OpenAI API key from SSM
OPENAI_API_KEY=$(aws ssm get-parameter --name /ticket-analyzer/dev/openai-api-key --with-decryption --query Parameter.Value --output text)

# Run container
docker run -d \
  --name ticket-analyzer-backend \
  --restart unless-stopped \
  -p 8000:8000 \
  -e OPENAI_API_KEY=$OPENAI_API_KEY \
  -e AWS_REGION=us-east-1 \
  -e DYNAMODB_TABLE_NAME=ticket-analyzer-dev-tickets \
  <ECR_REPO_URL>:latest
```

### 3.3 Verify Backend

```bash
curl http://localhost:8000/health
curl http://localhost:8000/docs
```

## Step 4: Frontend Deployment

### 4.1 Build Frontend

```bash
cd frontend
npm install

# Set API URL
export VITE_API_BASE_URL=http://<EC2_PUBLIC_IP>
npm run build
```

### 4.2 Deploy to S3

```bash
aws s3 sync dist/ s3://<S3_BUCKET_NAME> --delete
```

### 4.3 Invalidate CloudFront Cache

```bash
aws cloudfront create-invalidation \
  --distribution-id <CLOUDFRONT_DISTRIBUTION_ID> \
  --paths "/*"
```

## Step 5: Configure GitHub Actions

### 5.1 Set GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Add the following secrets:

- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `AWS_ACCOUNT_ID`: Your AWS account ID
- `EC2_HOST`: EC2 public IP or DNS
- `EC2_SSH_KEY`: Your private SSH key (for EC2 access)
- `DYNAMODB_TABLE_NAME`: DynamoDB table name
- `S3_BUCKET_NAME`: S3 bucket name
- `CLOUDFRONT_DISTRIBUTION_ID`: CloudFront distribution ID
- `API_BASE_URL`: Backend API URL (http://<EC2_IP>)

### 5.2 Test CI/CD

Push to `main` branch:

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

GitHub Actions will:
1. Run tests
2. Build Docker image
3. Push to ECR
4. Deploy to EC2
5. Build and deploy frontend

## Step 6: Dynatrace Setup

See [MONITORING.md](MONITORING.md) for detailed Dynatrace setup instructions.

Quick setup:

```bash
# On EC2 instance
wget -O Dynatrace-OneAgent-Linux.sh "https://<env>.live.dynatrace.com/api/v1/deployment/installer/agent/unix/default/latest?Api-Token=<token>"
chmod +x Dynatrace-OneAgent-Linux.sh
sudo ./Dynatrace-OneAgent-Linux.sh
```

## Step 7: Verify Deployment

### 7.1 Test API

```bash
# Health check
curl http://<EC2_IP>/health

# Create ticket
curl -X POST http://<EC2_IP>/tickets \
  -H "Content-Type: application/json" \
  -d '{
    "customer_email": "test@example.com",
    "subject": "Test ticket",
    "body": "This is a test ticket",
    "is_vip": false
  }'

# List tickets
curl http://<EC2_IP>/tickets
```

### 7.2 Test Frontend

1. Open CloudFront URL in browser
2. Create a test ticket
3. Verify it appears in dashboard
4. Check AI classification

## Troubleshooting

### Backend not starting

```bash
# Check Docker logs
docker logs ticket-analyzer-backend

# Check if container is running
docker ps -a

# Check environment variables
docker exec ticket-analyzer-backend env
```

### Frontend not loading

- Check S3 bucket permissions
- Verify CloudFront distribution is enabled
- Check browser console for errors
- Verify API URL is correct

### DynamoDB connection issues

- Check IAM role permissions
- Verify table name is correct
- Check AWS region matches

### CI/CD failures

- Verify all GitHub secrets are set
- Check AWS credentials have proper permissions
- Review GitHub Actions logs

## Cost Optimization (Free Tier)

- **EC2**: t2.micro is free tier eligible (750 hours/month)
- **DynamoDB**: PAY_PER_REQUEST (25 GB storage free)
- **S3**: 5 GB storage free
- **CloudFront**: 50 GB data transfer free
- **ECR**: 500 MB storage free

Monitor usage in AWS Cost Explorer to stay within free tier limits.

## Next Steps

1. Set up custom domain (optional)
2. Configure SSL/TLS certificates
3. Set up backup strategy
4. Implement monitoring alerts
5. Add more comprehensive tests
6. Set up staging environment

