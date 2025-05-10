# ECR Repository
resource "aws_ecr_repository" "main" {
  name = "${var.project}-${var.environment}"
  
  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"

  tags = var.tags
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

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