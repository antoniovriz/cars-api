# cars-api
cars api 
A README.md file with:
o Instructions to run the project locally.
o Explanation of the CI/CD pipeline.
o Description of the deployed architecture on AWS or LocalStack.
o Scalability and resilience strategies.
o Any relevant technical decisions.

## start project locally

### Requirements
- docker
- docker compose
- make (to execute Makefile tasks)

### Run the project

```shell
make init
make test
make dev
```

## CI/CD

1. Checks out the code from the repository so it can be built.

2. Authenticates with AWS using stored secrets, allowing access to services like ECR and ECS.

3. Logs into Amazon ECR, which is AWS's Docker image registry.

4. Builds a Docker image using the production Dockerfile, and tags it with:
  - The version from the GitHub release (e.g. v1.0.0)
  - latest

5. Pushes the Docker image to the ECR repository.

6. Updates the ECS task definition to use the new image version.

7. Deploys the updated task to ECS, forcing a new deployment so the service runs the latest version of the app.




