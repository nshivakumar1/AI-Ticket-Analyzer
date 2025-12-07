#!/bin/bash

# Dynatrace OneAgent Installation Script
# Usage: ./scripts/install-dynatrace.sh <ENVIRONMENT_ID> <API_TOKEN>

set -e

ENVIRONMENT_ID=${1:-""}
API_TOKEN=${2:-""}

if [ -z "$ENVIRONMENT_ID" ] || [ -z "$API_TOKEN" ]; then
    echo "Usage: ./scripts/install-dynatrace.sh <ENVIRONMENT_ID> <API_TOKEN>"
    echo "Example: ./scripts/install-dynatrace.sh abc12345 xyz-token-here"
    exit 1
fi

echo "Installing Dynatrace OneAgent..."

# Download installer
INSTALLER_URL="https://${ENVIRONMENT_ID}.live.dynatrace.com/api/v1/deployment/installer/agent/unix/default/latest?Api-Token=${API_TOKEN}&arch=x86&flavor=default"

echo "Downloading OneAgent installer..."
wget -O Dynatrace-OneAgent-Linux.sh "$INSTALLER_URL"

# Make executable
chmod +x Dynatrace-OneAgent-Linux.sh

# Install
echo "Installing OneAgent..."
sudo ./Dynatrace-OneAgent-Linux.sh

# Verify installation
if [ -f "/opt/dynatrace/oneagent/agent/lib64/liboneagentproc.so" ]; then
    echo "OneAgent installed successfully!"
    echo "Verifying version..."
    sudo /opt/dynatrace/oneagent/agent/lib64/liboneagentproc.so --version
else
    echo "Installation may have failed. Please check logs."
    exit 1
fi

# Check service status
if systemctl is-active --quiet oneagent; then
    echo "OneAgent service is running"
else
    echo "Warning: OneAgent service may not be running"
    sudo systemctl status oneagent
fi

echo ""
echo "Installation complete!"
echo "Next steps:"
echo "1. Check Dynatrace UI for your host"
echo "2. Verify services are being detected"
echo "3. Set up dashboards and alerts"

