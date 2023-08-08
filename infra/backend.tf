## Backend connected to Terraform Cloud. You can use local state provider/ another remote state provider or create a free Terraform Cloud Account and setup your organization and workspace. 
## Terraform Cloud Getting Started Guide - https://developer.hashicorp.com/terraform/tutorials/cloud-get-started?utm_source=WEBSITE&utm_medium=WEB_IO&utm_offer=ARTICLE_PAGE&utm_content=DOCS

terraform {
  cloud {
    organization = "ravnf-personal"

    workspaces {
      name = "ecs-security-workshop-infra"
    }
  }
}