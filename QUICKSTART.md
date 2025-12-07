# Quick Start Guide

Get the AI Support Ticket Analyzer running locally in 5 minutes.

## Prerequisites

- Python 3.11+
- Node.js 18+
- Docker (optional, for containerized setup)
- OpenAI API key

## Local Development Setup

### 1. Backend Setup

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
cp .env.example .env
# Edit .env and add your OPENAI_API_KEY

# Run the server
uvicorn app.main:app --reload
```

Backend will be available at `http://localhost:8000`
- API docs: `http://localhost:8000/docs`
- Health check: `http://localhost:8000/health`

### 2. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Create .env file
cp .env.example .env
# Edit .env and set VITE_API_BASE_URL=http://localhost:8000

# Run development server
npm run dev
```

Frontend will be available at `http://localhost:5173`

### 3. Test the Application

1. Open `http://localhost:5173` in your browser
2. Click "Create Ticket"
3. Fill in the form:
   - Email: test@example.com
   - Subject: Can't login to my account
   - Body: I'm unable to access my account. This is urgent!
4. Submit and see AI classification

## Docker Setup (Alternative)

```bash
# From project root
docker-compose up

# Backend: http://localhost:8000
# Frontend: Run separately with npm run dev
```

## Testing

### Backend Tests

```bash
cd backend
pytest tests/ -v
```

### Frontend Tests

```bash
cd frontend
npm test  # If you add tests
```

## Next Steps

- See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for AWS deployment
- See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for system design
- See [MONITORING.md](docs/MONITORING.md) for Dynatrace setup

## Troubleshooting

### Backend won't start
- Check Python version: `python --version` (should be 3.11+)
- Verify dependencies: `pip list`
- Check .env file exists and has OPENAI_API_KEY

### Frontend can't connect to API
- Verify backend is running on port 8000
- Check VITE_API_BASE_URL in frontend/.env
- Check CORS settings in backend

### AI analysis not working
- Verify OPENAI_API_KEY is set correctly
- Check API key has credits
- Review backend logs for errors

