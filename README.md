# AI Support Ticket Analyzer

AI-powered support ticket analyzer that classifies tickets (priority, category, sentiment), suggests resolutions, and exposes APIs + a minimal UI — fully deployed on AWS Free Tier with Terraform, GitHub Actions CI/CD, and Dynatrace monitoring.

## 🎯 Project Summary

This portfolio project demonstrates end-to-end DevOps practices:
- **Infrastructure as Code** with Terraform
- **CI/CD** with GitHub Actions
- **Containerization** with Docker
- **Cloud Deployment** on AWS (EC2, DynamoDB, S3, CloudFront)
- **Observability** with Dynatrace and CloudWatch
- **AI Integration** for intelligent ticket classification

## 🏗️ Architecture

```
┌─────────────────┐
│   CloudFront    │
│   (Frontend)    │
└────────┬────────┘
         │
    ┌────▼────┐
    │   S3    │
    │ (React) │
    └─────────┘

┌─────────────────┐
│   EC2 Instance  │
│  ┌───────────┐  │
│  │  Nginx    │  │
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │  FastAPI  │  │
│  │ Container │  │
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼─────┐  │
│  │Dynatrace  │  │
│  │ OneAgent  │  │
│  └───────────┘  │
└────────┬────────┘
         │
    ┌────▼────┐
    │DynamoDB │
    └─────────┘
```

## 🚀 Features

### Core Business Features
- **Smart Ticket Classification**: Auto-label tickets with priority (P1-P4), category, and sentiment
- **AI-Powered Suggestions**: LLM-generated response drafts for support agents
- **Ticket Dashboard**: Filter and view tickets by status, priority, category
- **Workflow Management**: Track tickets through New → In-Progress → Resolved

### Technical Features
- RESTful API with FastAPI
- Real-time AI analysis using OpenAI/LLM APIs
- Serverless frontend on S3 + CloudFront
- Infrastructure as Code with Terraform
- Automated CI/CD pipeline
- Comprehensive monitoring and observability

## 📁 Project Structure

```
.
├── backend/              # FastAPI application
│   ├── app/
│   │   ├── main.py      # FastAPI app entry point
│   │   ├── models.py    # Data models
│   │   ├── services/    # Business logic
│   │   │   ├── ai_service.py
│   │   │   └── dynamodb_service.py
│   │   └── routers/     # API routes
│   ├── tests/           # Unit tests
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/            # React application
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   └── services/
│   ├── package.json
│   └── Dockerfile
├── terraform/           # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
├── .github/
│   └── workflows/       # CI/CD pipelines
│       ├── backend.yml
│       └── frontend.yml
├── scripts/             # Deployment scripts
└── docs/                # Documentation
```

## 🛠️ Tech Stack

- **Backend**: Python 3.11, FastAPI, boto3, OpenAI API
- **Frontend**: React 18, TypeScript, TailwindCSS
- **Infrastructure**: AWS (EC2, DynamoDB, S3, CloudFront, IAM)
- **IaC**: Terraform
- **CI/CD**: GitHub Actions
- **Monitoring**: Dynatrace OneAgent, CloudWatch
- **Containerization**: Docker

## 🚦 Getting Started

### Prerequisites
- Python 3.11+
- Node.js 18+
- Terraform 1.5+
- AWS CLI configured
- Docker
- GitHub account with Actions enabled

### Local Development

#### Backend
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

#### Frontend
```bash
cd frontend
npm install
npm start
```

### Deployment

See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for detailed deployment instructions.

1. **Infrastructure Setup**
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

2. **Configure CI/CD**
   - Set GitHub Secrets (Settings -> Secrets and variables -> Actions):
     - **Credentials**:
       - `AWS_ACCESS_KEY_ID`
       - `AWS_SECRET_ACCESS_KEY`
       - `AWS_ACCOUNT_ID`
     - **Backend**:
       - `EC2_HOST` (Public IP of App Server)
       - `EC2_SSH_KEY` (Private Key Content)
       - `DYNAMODB_TABLE_NAME`
     - **Frontend**:
       - `S3_BUCKET_NAME`
       - `CLOUDFRONT_DISTRIBUTION_ID`
       - `API_BASE_URL` (e.g. `http://<EC2_HOST>:8000`)

3. **Deploy Backend**
   - Push to `main` branch triggers CI/CD
   - Or manually: `./scripts/deploy-backend.sh`

4. **Deploy Frontend**
   - Push to `main` branch triggers CI/CD
   - Or manually: `./scripts/deploy-frontend.sh`

## 📊 Monitoring

- **Dynatrace**: Service metrics, traces, host monitoring
- **CloudWatch**: Logs, custom metrics, alarms
- **Dashboards**: Request throughput, error rates, latency

## 📝 API Documentation

Once deployed, API docs available at:
- Swagger UI: `http://your-ec2-ip/docs`
- ReDoc: `http://your-ec2-ip/redoc`

## 🤝 Contributing

This is a portfolio project. Feel free to fork and enhance!

## 📄 License

MIT License

## 🔗 Links

- [Architecture Diagram](docs/ARCHITECTURE.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Monitoring Setup](docs/MONITORING.md)

