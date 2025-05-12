# ECR Repository for Client
resource "aws_ecr_repository" "client" {
  name = "${var.name_prefix}-client-repo"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECR Repository for Admin
resource "aws_ecr_repository" "admin" {
  name = "${var.name_prefix}-admin-repo"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECR Lifecycle Policy for Client
resource "aws_ecr_lifecycle_policy" "client" {
  repository = aws_ecr_repository.client.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Lifecycle Policy for Admin
resource "aws_ecr_lifecycle_policy" "admin" {
  repository = aws_ecr_repository.admin.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}