# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Users/Agents                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
         ┌───────────────────────┐
         │   CloudFront (CDN)    │
         │   Frontend Delivery   │
         └───────────┬───────────┘
                     │
         ┌───────────▼───────────┐
         │   S3 Bucket           │
         │   Static React App    │
         └───────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    EC2 Instance (t2.micro)                  │
│  ┌────────────────────────────────────────────────────────┐  │
│  │  Nginx (Reverse Proxy)                                │  │
│  │  - Routes /api/* to backend                            │  │
│  │  - Serves static files (optional)                      │  │
│  └───────────────┬───────────────────────────────────────┘  │
│                  │                                           │
│  ┌───────────────▼───────────────────────────────────────┐  │
│  │  Docker Container                                     │  │
│  │  ┌─────────────────────────────────────────────────┐ │  │
│  │  │  FastAPI Application                            │ │  │
│  │  │  - Ticket endpoints                             │ │  │
│  │  │  - AI Service (OpenAI integration)              │ │  │
│  │  │  - DynamoDB Service                             │ │  │
│  │  └─────────────────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Dynatrace OneAgent                                   │  │
│  │  - APM monitoring                                     │  │
│  │  - Infrastructure metrics                             │  │
│  │  - Service traces                                     │  │
│  └───────────────────────────────────────────────────────┘  │
└───────────────────────┬──────────────────────────────────────┘
                        │
        ┌───────────────┴───────────────┐
        │                               │
        ▼                               ▼
┌───────────────┐              ┌───────────────┐
│  DynamoDB     │              │  OpenAI API   │
│  Tickets Table│              │  (AI Analysis)│
└───────────────┘              └───────────────┘
```

## Component Details

### Frontend (React + TypeScript)

**Location**: S3 + CloudFront

**Responsibilities**:
- Ticket creation form
- Ticket dashboard with filters
- Ticket detail view
- Status management
- AI reanalysis trigger

**Tech Stack**:
- React 18
- TypeScript
- TailwindCSS
- Vite
- React Router

### Backend (FastAPI)

**Location**: EC2 Docker Container

**Responsibilities**:
- REST API endpoints
- Ticket CRUD operations
- AI integration
- DynamoDB operations
- Business logic

**Tech Stack**:
- Python 3.11
- FastAPI
- boto3 (AWS SDK)
- OpenAI API
- Pydantic

**API Endpoints**:
- `POST /tickets` - Create ticket with AI analysis
- `GET /tickets` - List tickets with filters
- `GET /tickets/{id}` - Get ticket details
- `PATCH /tickets/{id}` - Update ticket
- `POST /tickets/{id}/reanalyze` - Re-run AI analysis

### AI Service

**Integration**: OpenAI GPT-3.5-turbo

**Capabilities**:
- Priority classification (P1-P4)
- Category detection
- Sentiment analysis
- Suggested reply generation

**Fallback**: Rule-based analysis if API fails

### Data Storage

**DynamoDB Table**: `tickets`

**Schema**:
```json
{
  "ticket_id": "UUID (PK)",
  "created_at": "ISO timestamp",
  "updated_at": "ISO timestamp",
  "customer_email": "string",
  "customer_name": "string (optional)",
  "subject": "string",
  "body": "string",
  "priority": "P1|P2|P3|P4",
  "category": "string",
  "sentiment": "Angry|Neutral|Positive",
  "status": "New|In-Progress|Resolved",
  "ai_suggested_reply": "string",
  "is_vip": "boolean"
}
```

### Infrastructure

**EC2 Instance**:
- Type: t2.micro (free tier)
- OS: Amazon Linux 2
- Services: Docker, Nginx

**DynamoDB**:
- Billing: PAY_PER_REQUEST
- Free tier: 25 GB storage

**S3 + CloudFront**:
- Static website hosting
- CDN distribution
- Free tier: 5 GB storage, 50 GB transfer

**ECR**:
- Docker image registry
- Free tier: 500 MB storage

### CI/CD Pipeline

**GitHub Actions Workflows**:

1. **Backend Pipeline**:
   - Lint code
   - Run tests
   - Build Docker image
   - Push to ECR
   - Deploy to EC2

2. **Frontend Pipeline**:
   - Lint code
   - Build React app
   - Deploy to S3
   - Invalidate CloudFront cache

### Monitoring & Observability

**Dynatrace OneAgent**:
- Automatic service discovery
- APM tracing
- Infrastructure monitoring
- Custom metrics

**CloudWatch**:
- Log aggregation
- Custom metrics
- Alarms

## Data Flow

### Ticket Creation Flow

1. User submits ticket via frontend
2. Frontend sends POST to `/tickets` endpoint
3. FastAPI receives request
4. AI Service analyzes ticket:
   - Calls OpenAI API
   - Applies business rules
   - Generates classification
5. DynamoDB Service saves ticket
6. Response returned to frontend
7. Ticket appears in dashboard

### Ticket Analysis Flow

1. Ticket text extracted
2. Sent to OpenAI with prompt
3. AI returns JSON with:
   - Priority
   - Category
   - Sentiment
   - Suggested reply
4. Business rules applied (VIP bump, critical keywords)
5. Results stored in DynamoDB

## Security Considerations

1. **API Security**:
   - CORS configured
   - Input validation
   - Error handling

2. **AWS Security**:
   - IAM roles with least privilege
   - Security groups restrict access
   - SSM Parameter Store for secrets

3. **Network Security**:
   - HTTPS via CloudFront
   - Security groups on EC2
   - Private subnets (optional)

## Scalability Considerations

**Current (Free Tier)**:
- Single EC2 instance
- PAY_PER_REQUEST DynamoDB
- Static frontend

**Future Enhancements**:
- Auto Scaling Groups for EC2
- Application Load Balancer
- DynamoDB on-demand scaling
- Multiple availability zones
- Caching layer (Redis/ElastiCache)

## Cost Breakdown (Free Tier)

- **EC2 t2.micro**: 750 hours/month free
- **DynamoDB**: 25 GB storage free
- **S3**: 5 GB storage free
- **CloudFront**: 50 GB transfer free
- **ECR**: 500 MB storage free
- **Data Transfer**: 1 GB out free

**Estimated Monthly Cost**: $0-5 (within free tier limits)

## Deployment Environments

**Development**:
- Single EC2 instance
- Development DynamoDB table
- Test CloudFront distribution

**Production** (Future):
- Multi-AZ deployment
- Production DynamoDB table
- Custom domain with SSL
- Enhanced monitoring

