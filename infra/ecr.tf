resource "aws_ecr_repository" "user-api" {
  name                 = "user-api"
  image_tag_mutability = "MUTABLE"

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}