resource "aws_ecr_repository" "user-api" {
  name                 = "user-api"
  image_tag_mutability = "MUTABLE"

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}

resource "aws_ecr_lifecycle_policy" "user-api-ecr-lifecycle-policy" {
  repository = aws_ecr_repository.user-api.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "keep last 10 images"
        action       = {
          type = "expire"
        }
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
      }
    ]
  })
}