# Ansible Automation Guide

This project includes Ansible automation for deploying the backend and frontend, along with a UI (Ansible Semaphore) for managing these deployments.

## 📂 Structure

- `ansible/inventory.yml`: Defines the hosts (local and remote).
- `ansible/playbooks/deploy_backend.yml`: Deploys the FastAPI backend.
- `ansible/playbooks/deploy_frontend.yml`: Builds and syncs the React frontend to S3.
- `docker-compose.semaphore.yml`: Configuration for running Ansible Semaphore.

## 🚀 Running Ansible Semaphore (UI)

1.  Start the Semaphore UI:
    ```bash
    docker-compose -f docker-compose.semaphore.yml up -d
    ```

2.  Access the UI at `http://localhost:3000`.

3.  **Default Credentials**:
    - Email/Username: `admin`
    - Password: `admin`

4.  **First Time Setup**:
    - Login to Semaphore.
    - Create a new "Project" (e.g., "Ticket Analyzer").
    - **Key Store**: Add your SSH keys if deploying to remote servers.
    - **Environment**: Add secrets like `OPENAI_API_KEY`, `AWS_ACCESS_KEY_ID`, etc.
    - **Inventory**: Create an inventory (you can copy content from `ansible/inventory.yml` or use the file).
    - **Repositories**: Add this git repository.
    - **Task Templates**: Create templates for "Deploy Backend" and "Deploy Frontend" pointing to the respective playbooks.

## 💻 Running Playbooks Application Manually

You can also run playbooks directly using the `ansible-playbook` command if you have Ansible installed:

```bash
# Deploy Backend
ansible-playbook -i ansible/inventory.yml ansible/playbooks/deploy_backend.yml

# Deploy Frontend (Locally)
ansible-playbook -i ansible/inventory.yml ansible/playbooks/deploy_frontend.yml
```

## 🔧 Prerequisites for Remote Deployment

- SSH access to the target server (for backend).
- AWS CLI configured on the runner (for frontend S3 sync).
