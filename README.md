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

### Using AWS CLI

#### 1. Create ECR Repository

```bash
aws ecr create-repository --repository-name node-app
```

#### 2. Build & Push Image

```bash
aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com
docker build -t node-app .
docker tag node-app:latest <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/node-app:latest
docker push <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/node-app:latest
```

#### 3. Deploy to ECS Fargate

```bash
aws ecs create-cluster --cluster-name node-app-cluster
aws ecs register-task-definition --cli-input-json file://task-definition.json
aws ecs create-service --cluster node-app-cluster --service-name node-app-service --task-definition node-app --launch-type FARGATE --desired-count 1
```

### Using AWS Console (UI)

#### 1. Create ECR Repository

1. Go to **AWS Console** > **ECR** > **Repositories**
2. Click **Create repository**
3. Enter repository name: `node-app`
4. Click **Create repository**

#### 2. Push Image

1. Select your new repository
2. Click **View push commands**
3. Follow the 4 commands shown — they will be specific to your account and region:
   - **Command 1**: Authenticate Docker to ECR
   - **Command 2**: Build your image
   - **Command 3**: Tag your image
   - **Command 4**: Push your image

#### 3. Deploy to ECS Fargate

1. Go to **AWS Console** > **ECS** > **Clusters**
2. Click **Create cluster**
3. Select **Fargate** as infrastructure type
4. Enter cluster name and click **Create**
5. Go to **Task Definitions** > **Create new Task Definition**
6. Select **Fargate** launch type
7. Add container with your ECR image URI
8. Click **Create**
9. Go to your cluster > **Services** > **Create**
10. Select your task definition and configure networking
11. Click **Create service**
