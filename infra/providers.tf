provider "aws" {
  region     = var.aws-region
  access_key = var.aws-access-key # Define these on .tfvars file or use an environment with pre configured AWS access
  secret_key = var.aws-secret-key # Define these on .tfvars file or use an environment with pre configured AWS access
}