# Node.js App - Deploy to AWS ECR, ECS & Fargate

A simple Node.js app, built as a hands-on project for learning AWS deployment with ECR, ECS, and Fargate.

## Tech Stack

| Tech        | Description                                       |
| ----------- | ------------------------------------------------- |
| Node.js     | JavaScript runtime                                |
| Express     | Web framework for building REST APIs              |
| Docker      | Containerization platform                         |
| AWS ECR     | Elastic Container Registry - stores Docker images |
| AWS ECS     | Elastic Container Service - runs containers       |
| AWS Fargate | Serverless compute engine for ECS                 |
| AWS CLI     | Command-line tool for managing AWS services       |

## Prerequisites

- Node.js 22+
- Docker
- AWS CLI configured

## Local Development

```bash
npm install
npm run dev
```

## API Usage

```
GET /weather?q=manila
```

## Docker

```bash
docker build -t node-app .
docker run -p 5000:5000 -e API_ENDPOINT=https://api.openweathermap.org -e API_KEY=<API_KEY> node-app
```

## AWS Deployment

### 1. Create ECR Repository

```bash
aws ecr create-repository --repository-name node-app
```

### 2. Build & Push Image

```bash
aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com
docker build -t node-app .
docker tag node-app:latest <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/node-app:latest
docker push <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/node-app:latest
```

### 3. Deploy to ECS Fargate

- Create an ECS cluster
- Define a task using the Fargate launch type
- Use the pushed ECR image
- Configure networking and service
