# AWS Free Tier Optimization Analysis

## ✅ Currently Optimized (Good!)

### 1. **EC2 Instance**
- ✅ **Type**: `t2.micro` (Free Tier eligible)
- ✅ **Free Tier**: 750 hours/month (enough for 24/7 operation)
- ✅ **Default EBS**: 8GB gp2 (within 30GB free tier limit)
- ✅ **Using Default VPC**: No additional cost

### 2. **DynamoDB**
- ✅ **Billing Mode**: `PAY_PER_REQUEST` (On-Demand)
- ✅ **Free Tier**: 
  - 25 GB storage
  - 200M read requests/month
  - 200M write requests/month
- ✅ **No provisioned capacity costs**

### 3. **S3**
- ✅ **Storage Class**: Standard (default)
- ✅ **Free Tier**: 5 GB storage, 20,000 GET requests, 2,000 PUT requests
- ✅ **Public Access Blocked**: Security best practice

### 4. **CloudFront**
- ✅ **Free Tier**: 50 GB data transfer out, 2M HTTP/HTTPS requests
- ✅ **Optional**: Can be disabled if not needed

### 5. **ECR (Elastic Container Registry)**
- ✅ **Free Tier**: 500 MB storage/month
- ✅ **Image Scanning**: Free (no additional cost)

### 6. **CloudWatch Logs**
- ✅ **Retention**: 7 days (minimal cost)
- ✅ **Free Tier**: 5 GB ingestion, 5 GB storage

### 7. **SSM Parameter Store**
- ✅ **Free Tier**: 10,000 parameters (Standard tier)
- ✅ **SecureString**: Free for standard parameters

## ⚠️ Potential Optimizations

### 1. **S3 Versioning** (Minor Cost Impact)
**Current**: Enabled
**Impact**: Can increase storage costs if many versions are created
**Recommendation**: Disable for free tier, or make it optional

**Fix**:
```hcl
# Option 1: Disable versioning
resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = "Disabled"  # Changed from "Enabled"
  }
}

# Option 2: Make it configurable
variable "enable_s3_versioning" {
  description = "Enable S3 versioning (can increase costs)"
  type        = bool
  default     = false  # Disabled by default for free tier
}
```

### 2. **ECR Image Scanning** (No Cost, but uses resources)
**Current**: Enabled
**Impact**: Minimal - scanning is free but uses compute
**Recommendation**: Keep enabled (it's free and provides security)

### 3. **CloudFront Distribution** (Optional)
**Current**: Enabled by default
**Impact**: Free tier covers most use cases
**Recommendation**: Keep enabled (free tier is generous)

**Note**: Can be disabled if you don't need CDN:
```hcl
enable_cloudfront = false  # In terraform.tfvars
```

### 4. **EBS Volume Size** (Explicit is better)
**Current**: Uses default 8GB
**Recommendation**: Explicitly set to 8GB to stay within free tier

**Fix**:
```hcl
resource "aws_instance" "app" {
  # ... existing config ...
  
  root_block_device {
    volume_size = 8  # Free tier: 30GB total
    volume_type = "gp2"
  }
}
```

## 📊 Free Tier Limits Summary

| Service | Free Tier Limit | Current Usage | Status |
|---------|----------------|---------------|--------|
| EC2 t2.micro | 750 hrs/month | 1 instance | ✅ Within limit |
| EBS Storage | 30 GB | ~8 GB | ✅ Within limit |
| DynamoDB | 25 GB storage | Pay-per-request | ✅ Within limit |
| S3 Storage | 5 GB | < 1 GB (frontend) | ✅ Within limit |
| CloudFront | 50 GB transfer | Variable | ✅ Usually within limit |
| ECR Storage | 500 MB/month | ~100-200 MB | ✅ Within limit |
| CloudWatch Logs | 5 GB ingestion | Minimal | ✅ Within limit |

## 💰 Estimated Monthly Cost

**Within Free Tier**: **$0-2/month**

Potential costs (if you exceed free tier):
- **EC2**: $0.0116/hour after 750 hours = ~$0/month (if running 24/7, you get 750 hours free)
- **DynamoDB**: $0.25 per million requests after free tier
- **S3**: $0.023/GB after 5 GB
- **CloudFront**: $0.085/GB after 50 GB
- **Data Transfer**: $0.09/GB after 1 GB (outbound)

## 🎯 Recommendations

### For Maximum Free Tier Optimization:

1. **Disable S3 Versioning** (if not needed)
   - Saves on storage costs
   - Frontend deployments don't typically need versioning

2. **Set Explicit EBS Volume Size**
   - Ensures you stay within 30GB free tier
   - Makes costs predictable

3. **Monitor Usage**
   - Set up AWS Cost Explorer
   - Enable billing alerts
   - Monitor DynamoDB read/write units

4. **Optional: Disable CloudFront** (if not needed)
   - If you don't need CDN, can serve directly from S3
   - Saves on CloudFront costs (though free tier is generous)

## 🔧 Quick Optimization Fixes

I can update the Terraform configuration to:
1. Make S3 versioning optional (disabled by default)
2. Add explicit EBS volume size
3. Add cost monitoring tags
4. Add lifecycle policies for S3

Would you like me to apply these optimizations?

