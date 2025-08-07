o Description of the deployed architecture on AWS or LocalStack.
o Scalability and resilience strategies.
o Any relevant technical decisions.

## Start project locally

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

## CI/CD Pipelines

### ci/cd

- Checks out the code from the repository so it can be built.
- Authenticates with AWS using stored secrets, allowing access to services like ECR and ECS.
- Logs into Amazon ECR, which is AWS's Docker image registry.
- Builds a Docker image using the production Dockerfile, and tags it with:
  - The version from the GitHub release (e.g. v1.0.0)
  - latest
- Pushes the Docker image to the ECR repository.
- Updates the ECS task definition to use the new image version.
- Deploys the updated task to ECS, forcing a new deployment so the service runs the latest version of the app.

### pr_verify





