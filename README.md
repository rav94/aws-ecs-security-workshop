# AWS ECS Security Workshop

Repo contains resources created for demonstrating security features of AWS ECS. Originally created for the session titled "Securing Containerized Workloads on ECS" @ the August Monthly Meetup of AWS User Group - Colombo [31/08/2023]

## Directory Specification

*python-api* - Sample python api which is deployed as an ECS task. The API service is a REST API written in Python that talks to a backend database using DynamoDB. Copied from https://github.com/aws-containers/ecsdemo-migration-to-ecs.git

*infra* - Contains Terraform code for the sample infrastructure demonstrating security features of AWS ECS

## Notes

- **AWS Cloud9 is recommended for carrying out following actions.**
- **Infrastructure provisioned from running "terraform apply" within infra directory will incur costs. Ensure to run "terraform destroy" after testing these on your AWS accounts.**
- **Also enable AWS Budgets Alerts to notify you on AWS cloud bill passing a defined threshold.**

*python-api* 
- Build and push the Docker image from the given Dockerfile to your repository before creating ECS resources. 

*infra* 
- Refer backend.tf and comment it out to use Terraform local state or replace it with your own Terraform cloud configs or use another backend provider.
- Setup aws-access-key and aws-secret-key on terraform.tfvars file or deploy this within a environment which has respective permissions to access resources specified within this directory. 
- If you are on AWS Cloud9, the IAM role attached to Cloud9 takes care of the AWS permissions and you won't have to setup AWS access separately.
