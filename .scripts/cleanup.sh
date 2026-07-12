#!/bin/bash
set -e # Stop execution if a command fails

# ============================================================
# High-level cleanup process:
#   1. Delete ECS Service and wait for it to become inactive
#   2. Delete ECS Cluster
#   3. Deregister and delete all Task Definition revisions
#   4. Delete ECR Repository
#   5. Delete Secrets from Secrets Manager
#   6. Detach policies and delete IAM Role
#   7. Delete VPC networking (IGW, Subnets, Route Tables, SG, VPC)
#
# Estimated time: ~2-5 minutes (service deletion is the slowest step)
# ============================================================

# ============================================================
# 1. Cluster / Service / Task Definition cleanup
# ============================================================
echo "Deleting ECS Service..."
aws ecs delete-service --cluster node-app-dev-cluster --service node-app-dev-service --force || true

echo "Waiting for service deletion to finalize..."
aws ecs wait services-inactive --cluster node-app-dev-cluster --services node-app-dev-service || true

echo "Deleting ECS Cluster..."
aws ecs delete-cluster --cluster node-app-dev-cluster

echo "Deregistering and deleting Task Definitions..."
TASK_DEFS=$(aws ecs list-task-definitions --family-prefix node-app-dev-task --query "taskDefinitionArns[]" --output text)
for TASK_DEF in $TASK_DEFS; do
    echo "Deregistering: $TASK_DEF"
    aws ecs deregister-task-definition --task-definition "$TASK_DEF"
done
if [ -n "$TASK_DEFS" ]; then
    aws ecs delete-task-definitions --task-definitions $TASK_DEFS
fi


# ============================================================
# 2. Elastic Container Registry (ECR) cleanup
# ============================================================
echo "Deleting ECR Repository..."
aws ecr delete-repository --repository-name node-app --force


# ============================================================
# 3. Secrets Manager cleanup
# ============================================================
echo "Deleting Secrets..."
aws secretsmanager delete-secret --secret-id dev/node-app-api-endpoint --force-delete-without-recovery
aws secretsmanager delete-secret --secret-id dev/node-app-api-key --force-delete-without-recovery


# ============================================================
# 4. IAM Roles and Attached Policies cleanup
# ============================================================
echo "Cleaning up IAM Role..."
aws iam delete-role-policy --role-name ECSTaskExecutionRoleSecrets --policy-name GetSecretsValue-node-app-ecs-deploy
aws iam detach-role-policy --role-name ECSTaskExecutionRoleSecrets --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
aws iam delete-role --role-name ECSTaskExecutionRoleSecrets


# ============================================================
# 5. VPC & Security Group cleanup
# ============================================================
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=node-app-sg" --query "SecurityGroups[0].GroupId" --output text)
VPC_ID=$(aws ec2 describe-security-groups --group-ids "$SG_ID" --query "SecurityGroups[0].VpcId" --output text)

echo "Detaching and deleting Internet Gateways..."
for IGW in $(aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query "InternetGateways[*].InternetGatewayId" \
  --output text); do
    echo "Detaching and deleting IGW: $IGW"
    aws ec2 detach-internet-gateway --internet-gateway-id "$IGW" --vpc-id "$VPC_ID"
    aws ec2 delete-internet-gateway --internet-gateway-id "$IGW"
done

echo "Deleting Subnets..."
for SUBNET in $(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "Subnets[*].SubnetId" \
  --output text); do
    echo "Deleting Subnet: $SUBNET"
    aws ec2 delete-subnet --subnet-id "$SUBNET"
done

echo "Deleting Route Tables..."
for RTB in $(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query "RouteTables[?Associations[0].Main!=\`true\`].RouteTableId" \
  --output text); do
    echo "Deleting Route Table: $RTB"
    aws ec2 delete-route-table --route-table-id "$RTB"
done

echo "Deleting Security Group..."
aws ec2 delete-security-group --group-id "$SG_ID"

echo "Deleting VPC..."
aws ec2 delete-vpc --vpc-id "$VPC_ID"

echo "Cleanup successfully completed!"