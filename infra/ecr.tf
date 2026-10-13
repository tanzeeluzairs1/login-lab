resource "aws_ecr_repository" "app" {
  for_each = toset(["frontend", "backend"])

  name                 = "login-lab-${each.key}"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false
}

resource "aws_ecr_lifecycle_policy" "app" {
  for_each = aws_ecr_repository.app

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the five newest images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}