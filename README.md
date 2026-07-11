# Weather App - Deploy to AWS ECR, ECS & Fargate

A simple Node.js weather app using Express and OpenWeatherMap API, designed for deployment to AWS ECR, ECS, and Fargate.

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
GET /weather?q=Manila
```

## Docker

```bash
docker build -t weather-app-v2 .
docker run -p 5000:5000 -e API_ENDPOINT=https://api.openweathermap.org -e API_KEY=<API_KEY> weather-app-v2
```

## AWS Deployment

### 1. Create ECR Repository

```bash
aws ecr create-repository --repository-name weather-app-v2
```

### 2. Build & Push Image

```bash
aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com
docker build -t weather-app-v2 .
docker tag weather-app-v2:latest <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/weather-app-v2:latest
docker push <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/weather-app-v2:latest
```

### 3. Deploy to ECS Fargate

- Create an ECS cluster
- Define a task using the Fargate launch type
- Use the pushed ECR image
- Configure networking and service
