variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "ticket-analyzer"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the EC2 instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production
}

variable "openai_api_key" {
  description = "OpenAI API key (stored in SSM Parameter Store)"
  type        = string
  sensitive   = true
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
  default     = "tickets"
}

variable "ecr_repository_name" {
  description = "ECR repository name for Docker images"
  type        = string
  default     = "ticket-analyzer-backend"
}

variable "domain_name" {
  description = "Domain name for CloudFront (optional)"
  type        = string
  default     = ""
}

variable "enable_cloudfront" {
  description = "Enable CloudFront distribution"
  type        = bool
  default     = true
}

variable "enable_s3_versioning" {
  description = "Enable S3 versioning (can increase storage costs)"
  type        = bool
  default     = false  # Disabled by default for free tier optimization
}

variable "dynatrace_external_id" {
  description = "External ID for Dynatrace AWS Integration"
  type        = string
  sensitive   = true
}


variable "activegate_instance_type" {
  description = "Instance type for Dynatrace ActiveGate"
  type        = string
  default     = "t3.small"
}

variable "dynatrace_activegate_url" {
  description = "Download URL for Dynatrace ActiveGate installer (Linux Shell Script)"
  type        = string
  default     = ""
}

variable "dynatrace_api_token" {
  description = "Dynatrace API Token for ActiveGate download (from --header Authorization: Api-Token ...)"
  type        = string
  sensitive   = true
  default     = ""
}
