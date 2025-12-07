#!/bin/bash

# Setup script for EC2 instance
# Run this on the EC2 instance after initial setup

set -e

echo "Setting up EC2 instance for ticket analyzer..."

# Install Docker if not already installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo yum update -y
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -a -G docker ec2-user
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Install Nginx
if ! command -v nginx &> /dev/null; then
    echo "Installing Nginx..."
    sudo yum install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
fi

# Create Nginx configuration
echo "Creating Nginx configuration..."
sudo tee /etc/nginx/conf.d/ticket-analyzer.conf > /dev/null <<EOF
upstream backend {
    server localhost:8000;
}

server {
    listen 80;
    server_name _;

    # API proxy
    location /api/ {
        proxy_pass http://backend/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Frontend (if serving from EC2)
    location / {
        root /usr/share/nginx/html;
        try_files \$uri \$uri/ /index.html;
    }
}
EOF

# Test Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

echo "EC2 setup complete!"
echo "Next steps:"
echo "1. Deploy backend using deploy-backend.sh"
echo "2. Configure environment variables"
echo "3. Install Dynatrace OneAgent (see docs/MONITORING.md)"

