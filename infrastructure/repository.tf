resource "aws_ecr_repository" "shop" {
  name                 = "shop"

  image_scanning_configuration {
    scan_on_push = true
  }
}

