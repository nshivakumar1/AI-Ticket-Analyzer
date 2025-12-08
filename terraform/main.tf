terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Optional: Use S3 backend for state management
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "ticket-analyzer/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# VPC - Create a simple VPC (free tier friendly, no additional cost)
# This ensures we always have a VPC even if default VPC doesn't exist
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "free-tier"
  }
}

# Internet Gateway for VPC
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project_name}-${var.environment}-igw"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "free-tier"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-subnet"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "free-tier"
  }
}

# Route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-public-rt"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "free-tier"
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# DynamoDB Table
resource "aws_dynamodb_table" "tickets" {
  name           = "${var.project_name}-${var.environment}-${var.dynamodb_table_name}"
  billing_mode   = "PAY_PER_REQUEST"  # Free tier friendly
  hash_key       = "ticket_id"

  attribute {
    name = "ticket_id"
    type = "S"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-tickets"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "free-tier"  # Cost tracking tag
  }
}

# S3 Bucket for Frontend
resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.project_name}-${var.environment}-frontend-${random_id.bucket_suffix.hex}"
  force_destroy = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "free-tier"  # Cost tracking tag
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = var.enable_cloudfront
  block_public_policy     = var.enable_cloudfront
  ignore_public_acls      = var.enable_cloudfront
  restrict_public_buckets = var.enable_cloudfront
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = var.enable_s3_versioning ? "Enabled" : "Disabled"  # Configurable for free tier optimization
  }
}

# CloudFront Origin Access Identity
resource "aws_cloudfront_origin_access_identity" "frontend" {
  count = var.enable_cloudfront ? 1 : 0
  comment = "OAI for ${var.project_name} frontend"
}

# S3 Bucket Policy for CloudFront (Private)
resource "aws_s3_bucket_policy" "frontend" {
  count  = var.enable_cloudfront ? 1 : 0
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.frontend[0].iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

# S3 Bucket Configuration for Website Hosting (Public)
resource "aws_s3_bucket_website_configuration" "frontend" {
  count  = var.enable_cloudfront ? 0 : 1
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# S3 Bucket Policy for Website Hosting (Public)
resource "aws_s3_bucket_policy" "frontend_public" {
  count  = var.enable_cloudfront ? 0 : 1
  bucket = aws_s3_bucket.frontend.id
  depends_on = [aws_s3_bucket_public_access_block.frontend]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "frontend" {
  count   = var.enable_cloudfront ? 1 : 0
  enabled = true
  comment = "${var.project_name} frontend distribution"

  origin {
    domain_name = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.frontend.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend[0].cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend.id}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # Cache behavior for API calls (if needed)
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.frontend.id}"

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Content-Type"]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Security Group for EC2
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-${var.environment}-ec2-sg"
  description = "Security group for ticket analyzer EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "Backend API"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Role for EC2
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Policy for EC2
resource "aws_iam_role_policy" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ]
        Resource = aws_dynamodb_table.tickets.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/${var.project_name}/*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-profile"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ECR Repository
resource "aws_ecr_repository" "backend" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend"
    Environment = var.environment
    Project     = var.project_name
  }
}

# SSM Parameter for OpenAI API Key
resource "aws_ssm_parameter" "openai_api_key" {
  name        = "/${var.project_name}/${var.environment}/openai-api-key"
  description = "OpenAI API Key for ticket analyzer"
  type        = "SecureString"
  value       = var.openai_api_key

  tags = {
    Name        = "${var.project_name}-${var.environment}-openai-key"
    Environment = var.environment
    Project     = var.project_name
  }
}

# EC2 Instance
resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.ec2_instance_type
  key_name      = aws_key_pair.deployer.key_name  # You'll need to create this separately

  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  # Explicitly set root volume size to stay within free tier (30GB total)
  root_block_device {
    volume_size = 8  # 8GB root volume (within 30GB free tier limit)
    volume_type = "gp2"
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y docker git
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              
              # Install Docker Compose
              curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              
              # Install Nginx
              dnf install -y nginx
              systemctl start nginx
              systemctl enable nginx
              
              # Install CloudWatch agent (optional)
              dnf install -y amazon-cloudwatch-agent
              EOF

  tags = {
    Name        = "${var.project_name}-${var.environment}-app"
    Environment = var.environment
    Project     = var.project_name
    CostCenter  = "free-tier"  # Cost tracking tag
  }
}

# Generate a new SSH Key Pair
resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-${var.environment}-key-v2"
  public_key = tls_private_key.pk.public_key_openssh

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "local_file" "ssh_key" {
  content         = tls_private_key.pk.private_key_pem
  filename        = "../${var.project_name}-${var.environment}-key-v2.pem"
  file_permission = "0400"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.project_name}/${var.environment}/app"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Dynatrace IAM Role
resource "aws_iam_role" "dynatrace" {
  name = "${var.project_name}-${var.environment}-dynatrace-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::509560245411:root" # Dynatrace SaaS
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.dynatrace_external_id
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.activegate.arn # ActiveGate Instance Role
        }
        Action = "sts:AssumeRole"
        # No External ID required for internal ActiveGate
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-dynatrace-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach CloudWatchReadOnlyAccess
resource "aws_iam_role_policy_attachment" "dynatrace_cloudwatch" {
  role       = aws_iam_role.dynatrace.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

# Custom Policy for additional metrics (standard Dynatrace requirement)
resource "aws_iam_role_policy" "dynatrace_custom" {
  name = "${var.project_name}-${var.environment}-dynatrace-policy"
  role = aws_iam_role.dynatrace.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "apigateway:GET",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLaunchConfigurations",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "dynamodb:ListTables",
          "dynamodb:DescribeTable",
          "dynamodb:ListTagsOfResource",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSecurityGroups",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "lambda:ListFunctions",
          "lambda:ListTags",
          "rds:DescribeDBInstances",
          "rds:ListTagsForResource",
          "s3:ListAllMyBuckets",
          "sts:GetCallerIdentity",
          "tag:GetResources",
          "tag:GetTagKeys"
        ]
        Resource = "*"
      }
    ]
  })
}


# --- Dynatrace ActiveGate Infrastructure ---

# Security Group for ActiveGate
resource "aws_security_group" "activegate" {
  name        = "${var.project_name}-${var.environment}-activegate-sg"
  description = "Security Group for Dynatrace ActiveGate"
  vpc_id      = aws_vpc.main.id

  # Inbound: Allow internal traffic (OneAgent -> ActiveGate) on 9999
  ingress {
    from_port   = 9999
    to_port     = 9999
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
    description = "OneAgent traffic"
  }

  # Outbound: Allow HTTPS to Dynatrace SaaS
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS to Dynatrace SaaS"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for updates"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-activegate-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Role for ActiveGate (Instance Profile)
resource "aws_iam_role" "activegate" {
  name = "${var.project_name}-${var.environment}-activegate-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-activegate-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy" "activegate_custom" {
  name = "${var.project_name}-${var.environment}-activegate-policy"
  role = aws_iam_role.activegate.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "apigateway:GET",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLaunchConfigurations",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "dynamodb:ListTables",
          "dynamodb:DescribeTable",
          "dynamodb:ListTagsOfResource",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSecurityGroups",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "lambda:ListFunctions",
          "lambda:ListTags",
          "rds:DescribeDBInstances",
          "rds:ListTagsForResource",
          "s3:ListAllMyBuckets",
          "sts:GetCallerIdentity",
          "tag:GetResources",
          "tag:GetTagKeys"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.dynatrace.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "activegate" {
  name = "${var.project_name}-${var.environment}-activegate-profile"
  role = aws_iam_role.activegate.name
}

# EC2 Instance for ActiveGate
resource "aws_instance" "activegate" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.activegate_instance_type
  subnet_id     = aws_subnet.public.id 
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.activegate.id]
  iam_instance_profile   = aws_iam_instance_profile.activegate.name

  user_data = <<-EOF
              #!/bin/bash
              # Download and Install ActiveGate
              if [ -n "${var.dynatrace_activegate_url}" ] && [ -n "${var.dynatrace_api_token}" ]; then
                  wget -O Dynatrace-ActiveGate-Linux.sh "${var.dynatrace_activegate_url}" --header="Authorization: Api-Token ${var.dynatrace_api_token}"
                  if [ -f Dynatrace-ActiveGate-Linux.sh ]; then
                      sudo /bin/bash Dynatrace-ActiveGate-Linux.sh
                  else
                      echo "Failed to download ActiveGate installer"
                  fi
              else
                  echo "No ActiveGate URL or Token provided"
              fi
              EOF

  tags = {
    Name        = "${var.project_name}-${var.environment}-activegate"
    Environment = var.environment
    Project     = var.project_name
  }
}
