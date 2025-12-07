# Monitoring Setup with Dynatrace

This guide covers setting up Dynatrace OneAgent on the EC2 instance for comprehensive observability.

## Prerequisites

- Dynatrace account (free tier available)
- EC2 instance with SSH access
- Dynatrace environment URL and API token

## Step 1: Get Dynatrace OneAgent Installer

1. Log in to your Dynatrace environment
2. Navigate to **Deploy Dynatrace** → **OneAgent**
3. Select **Linux** as the platform
4. Copy the installation command

## Step 2: Install OneAgent on EC2

SSH into your EC2 instance and run:

```bash
# Download and install OneAgent
wget -O Dynatrace-OneAgent-Linux.sh "https://<your-environment>.live.dynatrace.com/api/v1/deployment/installer/agent/unix/default/latest?Api-Token=<your-token>&arch=x86&flavor=default"

# Make executable
chmod +x Dynatrace-OneAgent-Linux.sh

# Install
sudo ./Dynatrace-OneAgent-Linux.sh

# Verify installation
sudo /opt/dynatrace/oneagent/agent/lib64/liboneagentproc.so --version
```

## Step 3: Configure OneAgent

OneAgent will automatically detect:
- **Processes**: Your FastAPI application running in Docker
- **Services**: HTTP endpoints from your API
- **Infrastructure**: EC2 instance metrics (CPU, memory, disk, network)

## Step 4: Verify Monitoring

1. In Dynatrace, navigate to **Infrastructure** → **Hosts**
2. You should see your EC2 instance
3. Navigate to **Services** to see your FastAPI endpoints
4. Check **Processes** to see your Docker containers

## Step 5: Create Custom Dashboards

### Service Dashboard

1. Go to **Dashboards** → **Create dashboard**
2. Add tiles for:
   - **Service response time** (p50, p95, p99)
   - **Request count** by endpoint
   - **Error rate** (4xx, 5xx)
   - **Throughput** (requests per second)

### Infrastructure Dashboard

1. Add tiles for:
   - **Host CPU usage**
   - **Host memory usage**
   - **Disk I/O**
   - **Network throughput**

### Custom Metrics

You can send custom metrics from your application:

```python
# In your FastAPI app
from dynatrace import OneAgentSDK

sdk = OneAgentSDK()

# Track custom metric
sdk.add_custom_metric("ticket.created", 1, {"priority": "P1"})
```

## Step 6: Set Up Alerts

### Problem Detection Rules

1. Navigate to **Settings** → **Anomaly detection** → **Service**
2. Configure alerts for:
   - **High error rate** (>5%)
   - **High response time** (>2s p95)
   - **Service unavailable**

### Custom Alerts

1. Go to **Settings** → **Alerts** → **Custom events**
2. Create alert for:
   - CPU > 80% for 5+ minutes
   - Memory > 90%
   - Error rate spike

## Step 7: Integrate with CloudWatch

Dynatrace can ingest CloudWatch metrics:

1. In Dynatrace, go to **Settings** → **Cloud and virtualization** → **AWS**
2. Configure AWS integration with your credentials
3. Enable metrics for:
   - DynamoDB (read/write capacity, throttling)
   - EC2 (instance metrics)
   - S3 (bucket metrics)

## Step 8: Application Performance Monitoring (APM)

OneAgent automatically instruments:
- **HTTP requests** to your FastAPI endpoints
- **Database calls** to DynamoDB
- **External API calls** (OpenAI API)
- **Docker container** metrics

View traces in **Distributed traces** to see:
- Request flow through your application
- Time spent in each component
- Database query performance
- External API latency

## Troubleshooting

### OneAgent not detecting services

1. Check if OneAgent is running:
   ```bash
   sudo systemctl status oneagent
   ```

2. Verify Docker container is running:
   ```bash
   docker ps
   ```

3. Check OneAgent logs:
   ```bash
   sudo tail -f /var/log/dynatrace/oneagent/agent.log
   ```

### Services not appearing

- Ensure your FastAPI app is receiving traffic
- Check that ports are correctly exposed
- Verify OneAgent has proper permissions

## Best Practices

1. **Tag your services**: Add tags like `service=ticket-analyzer`, `env=dev`
2. **Set up SLIs/SLOs**: Define service level indicators
3. **Create runbooks**: Document common issues and resolutions
4. **Regular reviews**: Review dashboards weekly for trends

## Additional Resources

- [Dynatrace OneAgent Documentation](https://www.dynatrace.com/support/help/setup-and-configuration/dynatrace-oneagent)
- [Dynatrace API Documentation](https://www.dynatrace.com/support/help/dynatrace-api)
- [Custom Metrics Guide](https://www.dynatrace.com/support/help/extend-dynatrace/extend-dynatrace-via-oneagent-sdk)

