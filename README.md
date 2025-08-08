# 🛠️ Start Project Locally

## Requirements
- 🐳 **Docker**
- 🐳 **Docker Compose**
- 🛠️ **Make**

## Run the Project
    make init
    make test
    make dev

# 🔄 CI/CD Pipelines

## CI/CD Workflow
- 📦 **Code Checkout**: Retrieves the code from the repository for building.
- 🔐 **AWS Authentication**: Uses stored secrets to authenticate with AWS, enabling access to services like ECR and ECS.
- 🐳 **ECR Login**: Logs into Amazon ECR, AWS's Docker image registry.
- 🏗️ **Docker Image Build**: Builds a Docker image using the production Dockerfile, tagged with:
  - The GitHub release version (e.g., `v1.0.0`).
  - `latest`.
- 📤 **Push to ECR**: Uploads the Docker image to the ECR repository.
- 📝 **Update ECS Task Definition**: Modifies the ECS task definition to use the new image version.
- 🚀 **Deploy to ECS**: Forces a new deployment on ECS to run the latest application version.

# 🧾 Infrastructure Summary
This script provisions AWS infrastructure to deploy a containerized application using ECS Fargate with public access through an Application Load Balancer (ALB).

## 🔧 Components Created
- IAM Role & Policy
  - ecsTaskExecutionRole with permissions for ECS tasks.
- CloudWatch Log Group
  - /ecs/api-cars for capturing application logs.
- ECS Task Definition
  - Defines the container (api-cars-container) and config.
- ECS Cluster & Service
  - Runs the app on Fargate (api-cars-cluster, service: api).
- Application Load Balancer (ALB)
  - Public-facing ALB (fargate-alb) for HTTP traffic.
- Target Group & Listener
  - Routes traffic from ALB to the running container.
- Networking
  - Uses existing VPC, subnets, and security group.
