#!/bin/bash
# Exporting this, will disable the AWS CLI pager
# which is useful for scripts to avoid pagination issues.
export AWS_PAGER=""

# Configuration values
REGION="eu-west-1"
ACCOUNT_ID="390000028094"
CLUSTER_NAME="api-cars-cluster"
SERVICE_NAME="api"
CONTAINER_NAME="api-cars-container"
CONTAINER_PORT=80
SUBNETS=("subnet-0980e972a9c44888a" "subnet-0b293ec7e07dbdc08")
SECURITY_GROUP="sg-0ba7229bc32ddb3ac"
VPC_ID="vpc-07916a60c6fd2477f"
ALB_NAME="fargate-alb"
TARGET_GROUP_NAME="fargate-targets"

# We assume we have a VPC and subnets already created,
# if not, you can create them using the AWS console or CLI.
# Ensure jq is installed for JSON parsing

# Step 1: Create IAM Role for ECS Task Execution
echo "Creating IAM role for ECS Task Execution..."
aws iam create-role --role-name ecsTaskExecutionRole --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}'
if [ $? -ne 0 ]; then
  echo "Error creating IAM role"
  exit 1
fi
echo "IAM role created successfully."

# Step 1.1: Attach the ECS Task Execution Policy
echo "Creating IAM policy for ECS Task Execution..."
aws iam create-policy --policy-name ECSParameterStoreAccess --policy-document file://parameter-store-policy.json
if [ $? -ne 0 ]; then
  echo "Error creating IAM policy"
  exit 1
fi
echo "Policy created successfully."

# Step 1.2: Attach the policy to the role
echo "Attaching policy to IAM role..."
aws iam attach-role-policy --role-name ecsTaskExecutionRole --policy-arn "arn:aws:iam::$ACCOUNT_ID:policy/ECSParameterStoreAccess"
if [ $? -ne 0 ]; then
  echo "Error attaching policy to IAM role"
  exit 1
fi
echo "Policy attached successfully."

# Step 2: register the ECS Task Definition
echo "Registering ECS Task Definition..."
TASK_DEFINITION_REVISION=$(aws ecs register-task-definition --cli-input-json file://task.json | jq '.taskDefinition.revision')

# Step 3: Create the ECS Cluster
echo "Creating ECS Cluster: $CLUSTER_NAME..."
aws ecs create-cluster --cluster-name api-cars-cluster
if [ $? -ne 0 ]; then
  echo "Error creating ECS Cluster"
  exit 1
fi
echo "ECS Cluster created successfully."

# Step 4: Create the ECS Service
echo "Creating ECS Service: $SERVICE_NAME..."
aws ecs create-service --cluster api-cars-cluster --service-name api --task-definition apis:$TASK_DEFINITION_REVISION --desired-count 1 --launch-type "FARGATE" --network-configuration "awsvpcConfiguration={subnets=[subnet-0980e972a9c44888a],securityGroups=[sg-0ba7229bc32ddb3ac],assignPublicIp=ENABLED}"
if [ $? -ne 0 ]; then
  echo "Error creating ECS Service"
  exit 1
fi
echo "ECS Service created successfully."

# Step 5: Create the Application Load Balancer
echo "Creating ALB: $ALB_NAME..."
ALB_OUTPUT=$(aws elbv2 create-load-balancer \
  --name "$ALB_NAME" \
  --subnets "${SUBNETS[@]}" \
  --security-groups "$SECURITY_GROUP" \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4 \
  --region "$REGION" \
  --query "LoadBalancers[0].{LoadBalancerArn:LoadBalancerArn,DNSName:DNSName}" \
  --output json)
if [ $? -ne 0 ]; then
  echo "Error creating ALB"
  exit 1
fi
echo "ALB created successfully."

# Extract ALB ARN and DNS with jq
ALB_ARN=$(echo "$ALB_OUTPUT" | jq -r .LoadBalancerArn)
ALB_DNS=$(echo "$ALB_OUTPUT" | jq -r .DNSName)
echo "ALB ARN: $ALB_ARN, DNS: $ALB_DNS"

# Step 6: Create the Target Group
echo "Creating Target Group: $TARGET_GROUP_NAME..."
TARGET_GROUP_ARN=$(aws elbv2 create-target-group \
  --name "$TARGET_GROUP_NAME" \
  --protocol HTTP \
  --port 80 \
  --vpc-id "$VPC_ID" \
  --target-type ip \
  --health-check-protocol HTTP \
  --health-check-path / \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 2 \
  --region "$REGION" \
  --query "TargetGroups[0].TargetGroupArn" \
  --output text)

if [ $? -ne 0 ]; then
  echo "Error creating Target Group"
  exit 1
fi
echo "Target Group created successfully - ARN: $TARGET_GROUP_ARN"

# Step 7: Create a listener for the ALB
echo "Creating listener for ALB..."
LISTENER_INFO=$(aws elbv2 create-listener \
  --load-balancer-arn "$ALB_ARN" \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn="$TARGET_GROUP_ARN" \
  --region "$REGION")
LISTENER_ARN=$(echo "$LISTENER_INFO" | jq -r .Listeners[0].ListenerArn)
echo "Listener created - ARN: $LISTENER_ARN"

# Step 8: Register the ECS Service with the Target Group
echo "Registering ECS Service with Target Group..."
aws ecs update-service --cluster "$CLUSTER_NAME" \
  --service "$SERVICE_NAME" \
  --force-new-deployment \
  --region "$REGION" \
  --load-balancers "targetGroupArn=$TARGET_GROUP_ARN,containerName=$CONTAINER_NAME,containerPort=$CONTAINER_PORT"
if [ $? -ne 0 ]; then
  echo "Error registering ECS Service with Target Group"
  exit 1
fi
echo "ECS Service registered with Target Group successfully."

echo "🚀 Deployment completed successfully."