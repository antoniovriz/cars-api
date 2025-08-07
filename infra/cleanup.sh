#!/bin/bash
# Exporting this to disable the AWS CLI pager for scripts
export AWS_PAGER=""

# Configuration values (match the original script)
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

# Ensure jq is installed for JSON parsing
if ! command -v jq &> /dev/null; then
  echo "Error: jq is required for JSON parsing. Please install jq."
  exit 1
fi
echo "Starting cleanup process..."
# Step 0: Delete the CloudWatch Log Group
echo "Deleting CloudWatch Log Group for ECS Task..."
aws logs delete-log-group \
  --log-group-name /ecs/api-cars \
  --region eu-west-1
if [ $? -ne 0 ]; then
  echo "Error deleting CloudWatch Log Group"
  #exit 1
fi
echo "CloudWatch Log Group deleted successfully."

# Step 1: Delete the ECS Service
echo "Deleting ECS Service: $SERVICE_NAME..."
SERVICE_EXISTS=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME" --region "$REGION" --query "services[0].status" --output text 2>/dev/null)
if [ "$SERVICE_EXISTS" == "ACTIVE" ] || [ "$SERVICE_EXISTS" == "DRAINING" ]; then
  aws ecs update-service --cluster "$CLUSTER_NAME" --service "$SERVICE_NAME" --desired-count 0 --region "$REGION"
  aws ecs delete-service --cluster "$CLUSTER_NAME" --service "$SERVICE_NAME" --force --region "$REGION"
  if [ $? -ne 0 ]; then
    echo "Error deleting ECS Service"
    exit 1
  fi
  echo "ECS Service deleted successfully."
else
  echo "ECS Service $SERVICE_NAME does not exist or is already deleted."
fi

# Step 2: Deregister the ECS Task Definition
echo "Deregistering ECS Task Definition: apis..."
TASK_REVISIONS=$(aws ecs list-task-definitions --family-prefix apis --region "$REGION" --query "taskDefinitionArns" --output text)
for TASK_ARN in $TASK_REVISIONS; do
  aws ecs deregister-task-definition --task-definition "$TASK_ARN" --region "$REGION"
  if [ $? -ne 0 ]; then
    echo "Error deregistering task definition $TASK_ARN"
    exit 1
  fi
  echo "Task definition $TASK_ARN deregistered successfully."
done

# Step 3: Delete the ALB Listener
echo "Finding and deleting ALB Listener for ALB: $ALB_NAME..."
ALB_ARN=$(aws elbv2 describe-load-balancers --names "$ALB_NAME" --region "$REGION" --query "LoadBalancers[0].LoadBalancerArn" --output text 2>/dev/null)
if [ -n "$ALB_ARN" ]; then
  LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN" --region "$REGION" --query "Listeners[0].ListenerArn" --output text 2>/dev/null)
  if [ -n "$LISTENER_ARN" ]; then
    aws elbv2 delete-listener --listener-arn "$LISTENER_ARN" --region "$REGION"
    if [ $? -ne 0 ]; then
      echo "Error deleting ALB Listener"
      exit 1
    fi
    echo "ALB Listener deleted successfully."
  else
    echo "No listener found for ALB $ALB_NAME."
  fi
else
  echo "ALB $ALB_NAME does not exist or is already deleted."
fi

# Step 4: Delete the Target Group
echo "Deleting Target Group: $TARGET_GROUP_NAME..."
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names "$TARGET_GROUP_NAME" --region "$REGION" --query "TargetGroups[0].TargetGroupArn" --output text 2>/dev/null)
if [ -n "$TARGET_GROUP_ARN" ]; then
  aws elbv2 delete-target-group --target-group-arn "$TARGET_GROUP_ARN" --region "$REGION"
  if [ $? -ne 0 ]; then
    echo "Error deleting Target Group"
    exit 1
  fi
  echo "Target Group deleted successfully."
else
  echo "Target Group $TARGET_GROUP_NAME does not exist or is already deleted."
fi

# Step 5: Delete the Application Load Balancer
echo "Deleting ALB: $ALB_NAME..."
if [ -n "$ALB_ARN" ]; then
  aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" --region "$REGION"
  if [ $? -ne 0 ]; then
    echo "Error deleting ALB"
    exit 1
  fi
  echo "ALB deleted successfully."
else
  echo "ALB $ALB_NAME does not exist or is already deleted."
fi

# Step 6: Delete the ECS Cluster
echo "Deleting ECS Cluster: $CLUSTER_NAME..."
CLUSTER_EXISTS=$(aws ecs describe-clusters --clusters "$CLUSTER_NAME" --region "$REGION" --query "clusters[0].status" --output text 2>/dev/null)
if [ "$CLUSTER_EXISTS" == "ACTIVE" ]; then
  aws ecs delete-cluster --cluster "$CLUSTER_NAME" --region "$REGION"
  if [ $? -ne 0 ]; then
    echo "Error deleting ECS Cluster"
    exit 1
  fi
  echo "ECS Cluster deleted successfully."
else
  echo "ECS Cluster $CLUSTER_NAME does not exist or is already deleted."
fi

# Step 7: Detach and Delete IAM Policy
echo "Detaching IAM policy ECSAccess..."
POLICY_ARN="arn:aws:iam::$ACCOUNT_ID:policy/ECSAccess"
POLICY_EXISTS=$(aws iam get-policy --policy-arn "$POLICY_ARN" --region "$REGION" --query "Policy.Arn" --output text 2>/dev/null)
if [ -n "$POLICY_EXISTS" ]; then
  aws iam detach-role-policy --role-name ecsTaskExecutionRole --policy-arn "$POLICY_ARN"
  if [ $? -ne 0 ]; then
    echo "Error detaching IAM policy"
    exit 1
  fi
  echo "IAM policy detached successfully."

  echo "Deleting IAM policy ECSAccess..."
  aws iam delete-policy --policy-arn "$POLICY_ARN"
  if [ $? -ne 0 ]; then
    echo "Error deleting IAM policy"
    exit 1
  fi
  echo "IAM policy deleted successfully."
else
  echo "IAM policy ECSAccess does not exist or is already deleted."
fi

# Step 8: Delete IAM Role (Optional)
echo "WARNING: Deleting the IAM role ecsTaskExecutionRole may affect other services."
read -p "Do you want to delete the ecsTaskExecutionRole? (y/n): " DELETE_ROLE
if [ "$DELETE_ROLE" == "y" ]; then
  echo "Checking for attached policies on ecsTaskExecutionRole..."
  ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name ecsTaskExecutionRole --region "$REGION" --query "AttachedPolicies[].PolicyArn" --output text)
  if [ -n "$ATTACHED_POLICIES" ]; then
    echo "Cannot delete role: Other policies are still attached ($ATTACHED_POLICIES)."
    exit 1
  fi
  echo "Deleting IAM role ecsTaskExecutionRole..."
  aws iam delete-role --role-name ecsTaskExecutionRole
  if [ $? -ne 0 ]; then
    echo "Error deleting IAM role"
    exit 1
  fi
  echo "IAM role deleted successfully."
else
  echo "Skipping IAM role deletion."
fi

echo "🚀 Cleanup completed successfully."
