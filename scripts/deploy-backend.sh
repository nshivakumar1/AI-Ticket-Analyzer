#!/bin/bash

# Deploy backend to EC2
# Usage: ./scripts/deploy-backend.sh

set -e

AWS_REGION=${AWS_REGION:-us-east-1}
ECR_REPOSITORY=${ECR_REPOSITORY:-ticket-analyzer-backend}
EC2_HOST=${EC2_HOST:-""}
EC2_USER=${EC2_USER:-ec2-user}

if [ -z "$EC2_HOST" ]; then
    echo "Error: EC2_HOST environment variable not set"
    exit 1
fi

echo "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com

ECR_REGISTRY=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com
IMAGE_TAG=${IMAGE_TAG:-latest}

echo "Building Docker image..."
cd backend
docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .

echo "Pushing image to ECR..."
docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG

echo "Deploying to EC2..."
ssh $EC2_USER@$EC2_HOST << EOF
    # Login to ECR
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY
    
    # Pull latest image
    docker pull $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
    
    # Stop and remove old container
    docker stop ticket-analyzer-backend || true
    docker rm ticket-analyzer-backend || true
    
    # Get OpenAI API key from SSM
    OPENAI_API_KEY=\$(aws ssm get-parameter --name /ticket-analyzer/dev/openai-api-key --with-decryption --query Parameter.Value --output text)
    
    # Run new container
    docker run -d \\
      --name ticket-analyzer-backend \\
      --restart unless-stopped \\
      -p 8000:8000 \\
      -e OPENAI_API_KEY=\$OPENAI_API_KEY \\
      -e AWS_REGION=$AWS_REGION \\
      -e DYNAMODB_TABLE_NAME=\$(aws dynamodb list-tables --query 'TableNames[?contains(@, `tickets`)]' --output text) \\
      $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
EOF

echo "Deployment complete!"

