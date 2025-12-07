#!/bin/bash

# Deploy frontend to S3
# Usage: ./scripts/deploy-frontend.sh

set -e

AWS_REGION=${AWS_REGION:-us-east-1}
S3_BUCKET=${S3_BUCKET:-""}
CLOUDFRONT_DISTRIBUTION_ID=${CLOUDFRONT_DISTRIBUTION_ID:-""}

if [ -z "$S3_BUCKET" ]; then
    echo "Error: S3_BUCKET environment variable not set"
    exit 1
fi

echo "Building frontend..."
cd frontend
npm install
npm run build

echo "Deploying to S3..."
aws s3 sync dist/ s3://$S3_BUCKET --delete --region $AWS_REGION

if [ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]; then
    echo "Invalidating CloudFront cache..."
    aws cloudfront create-invalidation \
        --distribution-id $CLOUDFRONT_DISTRIBUTION_ID \
        --paths "/*" \
        --region $AWS_REGION
fi

echo "Deployment complete!"

