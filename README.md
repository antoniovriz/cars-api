# Demos
- Launch project locally
- Deploying new infra through `aws-deploy.sh`
- Releasing a new version
- Rollback to a previous version
- Destroying existing infrastructure throug `cleanup.sh`

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

# 🚀 Future Scalability Enhancements

To further improve the scalability of the containerized application deployed on AWS ECS Fargate, the following strategies are planned for future implementation:

## 🔮 Planned Scalability Improvements

- **Dynamic Auto-Scaling Policies (future)** 📈
  - Introduce advanced auto-scaling rules using predictive scaling with AWS Application Auto Scaling. This will leverage machine learning to forecast traffic patterns and proactively adjust the number of ECS tasks, optimizing resource usage and reducing latency during unexpected spikes.

- **Container Optimization** 🐳
  - Optimize container images by adopting lightweight base images (e.g., Alpine Linux) and implementing multi-stage Docker builds to reduce image size and startup times, enabling faster scaling and lower resource consumption.

- **Caching Layer Integration** ⚡
  - Integrate Amazon ElastiCache (Redis or Memcached) to cache frequently accessed data, reducing database load and improving response times. This will enhance scalability by offloading repetitive queries from the backend.

- **Content Delivery Network (CDN)** 🌍
  - Implement Amazon CloudFront as a CDN to cache static assets and API responses at edge locations, reducing latency for global users and minimizing load on the ALB and ECS tasks.

- **Serverless Compute for Bursty Workloads** ☁️
  - Migrate specific workloads (e.g., background tasks or event-driven processes) to AWS Lambda, enabling instant scaling for unpredictable traffic without provisioning additional ECS tasks.

- **Database Sharding and Read Replicas** 🗄️
  - Enhance database scalability by implementing sharding for write-heavy operations and read replicas for read-heavy queries using Amazon RDS or Aurora. This will distribute database load and improve performance under high traffic.

