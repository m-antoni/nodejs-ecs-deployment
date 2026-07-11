# Node.js App - Deploy to AWS ECR, ECS, Fargate & VPC

A simple Node.js app, built as a hands-on project for learning AWS deployment with ECR, ECS, and Fargate.

## Tech Stack

| Tech                | Description                                       |
| ------------------- | ------------------------------------------------- |
| Node.js             | JavaScript runtime                                |
| Express             | Web framework for building REST APIs              |
| Docker              | Containerization platform                         |
| AWS ECR             | Elastic Container Registry - stores Docker images |
| AWS ECS             | Elastic Container Service - runs containers       |
| AWS Fargate         | Serverless compute engine for ECS                 |
| AWS Secrets Manager | Stores and manages secrets like API keys          |
| AWS IAM             | Manages access roles and permissions              |
| AWS CLI             | Command-line tool for managing AWS services       |

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

1. Go to **AWS Console** > **ECR** > **Repositories**
2. Click **Create repository**
3. Enter repository name: `node-app`
4. Click **Create repository**

#### 1.1 Push Image

1. Select your new repository
2. Click **View push commands**
3. Follow the 4 commands shown — they will be specific to your account and region:
   - **Command 1**: Authenticate Docker to ECR
   - **Command 2**: Build your image
   - **Command 3**: Tag your image
   - **Command 4**: Push your image

### 2. Create Secret

1. Go to **AWS Console** > **Secrets Manager**
2. Click **Store a new secret**
3. Select **Other type of secret**
4. Enter key-value pairs:
   - Key: `API_ENDPOINT`, Value: `https://api.openweathermap.org`
   - Key: `API_KEY`, Value: your API key
5. Enter name: `dev/node-app-ecs-deploy`
6. Click **Store**

### 3. Create IAM Role

1. Go to **AWS Console** > **IAM** > **Roles**
2. Click **Create role**
3. Select **AWS service** as trusted entity
4. Choose **Elastic Container Service** as use case
5. Select **Elastic Container Service Task** and click **Next**
6. Click **Create policy** (opens new tab)
7. Select **JSON** tab and enter:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:ap-southeast-1:<AWS_ID>:secret:dev/node-app-ecs-deploy-*"
    }
  ]
}
```

8. Name policy: `node-app-ecs-secrets-policy` > Click **Create policy**
9. Go back to role creation tab > refresh policies
10. Search and select `node-app-ecs-secrets-policy`
11. Also select `AmazonECSTaskExecutionRolePolicy`
12. Click **Next**
13. Enter role name: `ECSTaskExecutionRoleSecrets`
14. Click **Create role**

### 4. Deploy to ECS Fargate

#### 4.1 Create ECS Cluster

1. Go to **AWS Console** > **ECS** > **Clusters**
2. Click **Create cluster**
3. Select **Fargate** as infrastructure type
4. Enter cluster name: `node-app-dev-cluster` and click **Create**

#### 4.2 Create Task Definition

1. Go to **Task Definitions** > **Create new Task Definition**
2. Enter family name: `node-app-dev-task`
3. Select **Fargate** launch type
4. Under **Task execution role**, select `ECSTaskExecutionRoleSecrets`
5. Add container with your ECR image URI
6. Under **Port mappings**, set container port to `5000`
7. Under **Environment variables**, value type > **ValueFrom** add both from Secrets Manager ARN:
   - `API_ENDPOINT` from `dev/node-app-ecs-deploy`
   - `API_KEY` from `dev/node-app-ecs-deploy`
8. Click **Create**

#### 4.3 Create VPC

1. Go to **AWS Console** > **VPC** > **Your VPCs**
2. Click **Create VPC**
3. Select **VPC and more**
4. Set **IPv4 CIDR** = `10.0.0.0/16`
5. Set **Public subnets** = 2
6. Click **Create VPC**

#### 4.4 Create Security Group

1. Go to **AWS Console** > **VPC** > **Security Groups**
2. Click **Create security group**
3. Enter name: `node-app-sg`
4. Select your VPC
5. Under **Inbound rules**, click **Add rule**:
   - Type: **Custom TCP**
   - Port: `5000`
   - Source: **Anywhere** (`0.0.0.0/0`)
6. Click **Create security group**

#### 4.5 Create Service

1. Go to **AWS Console** > **ECS** > **Clusters** > `node-app-dev-cluster`
2. Click **Services** > **Create**
3. Select your task definition
4. Under **Networking**, select:
   - VPC: your VPC
   - Subnets: 2 subnets
   - Security groups: `node-app-sg`
5. Enable **Auto-assign public IP**
6. Click **Create service**

> **Note:** Service creation takes 2-5 minutes. AWS is provisioning Fargate infrastructure, pulling your Docker image from ECR, starting the container, configuring networking (ENI, public IP), and running health checks. If it takes longer, check the **Events** tab for errors.

### 5. Access the Web App

1. Go to **ECS** > **Clusters** > `node-app-dev-cluster`
2. Click on your service (`node-app-dev-service`)
3. Click on the **Tasks** tab
4. Click on the running task
5. Under **Network** section, copy the **Public IP**
6. Open in browser:
   ```
   http://<PUBLIC_IP>:5000
   http://<PUBLIC_IP>:5000/weather?q=manila
   ```

> **Note:** If the task keeps stopping, click on the task > **Logs** tab to check for errors.

## Rollback / Cleanup

Delete all AWS resources to avoid unnecessary charges.

### Using AWS CLI

```bash
# Delete ECS service
aws ecs update-service --cluster node-app-dev-cluster --service node-app-dev-service --desired-count 0
aws ecs delete-service --cluster node-app-dev-cluster --service node-app-dev-service

# Delete task definition
aws ecs deregister-task-definition --task-definition node-app-dev-task:1

# Delete ECS cluster
aws ecs delete-cluster --cluster node-app-dev-cluster

# Delete ECR repository
aws ecr delete-repository --repository-name node-app --force

# Delete secret
aws secretsmanager delete-secret --secret-id dev/node-app-ecs-deploy --force-delete

# Delete IAM role
aws iam detach-role-policy --role-name ECSTaskExecutionRoleSecrets --policy-arn arn:aws:iam::aws:policy/SecretsManagerReadWrite
aws iam detach-role-policy --role-name ECSTaskExecutionRoleSecrets --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
aws iam delete-role --role-name ECSTaskExecutionRoleSecrets

# Delete security group
aws ec2 delete-security-group --group-name node-app-sg

# Delete VPC (must delete subnets first)
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<VPC_ID>" --query "Subnets[*].SubnetId" --output text | xargs -n1 aws ec2 delete-subnet --subnet-id
aws ec2 delete-vpc --vpc-id <VPC_ID>
```

### Using AWS Console (UI)

1. Go to **ECS** > **Clusters** > select cluster
2. Select service > **Update** > set desired count to **0** > save
3. Select service > **Delete**
4. Go to **Task Definitions** > select task > **Deregister**
5. Go to **ECS** > **Clusters** > select cluster > **Delete**
6. Go to **ECR** > select repository > **Delete**
7. Go to **Secrets Manager** > select `dev/node-app-ecs-deploy` > **Delete**
8. Go to **IAM** > **Roles** > select `ECSTaskExecutionRoleSecrets` > **Delete**
9. Go to **VPC** > **Security Groups** > select `node-app-sg` > **Delete**
10. Go to **VPC** > **Your VPCs** > select VPC > **Delete** (delete subnets first)
