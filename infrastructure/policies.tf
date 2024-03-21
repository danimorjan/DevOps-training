resource "aws_iam_policy" "allow_ec2_pull" {
  name        = "Ec2-allow-push-policy"
  description = "Allows necessary actions on an ECR repository"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
        ],
        Resource = "${aws_ecr_repository.shop.arn}"
      },
      {
        Effect   = "Allow",
        Action   = "ecr:GetAuthorizationToken",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "ecr_allow_push_policy" {
  name        = "ECR-Allow-Push-Policy"
  description = "Allows necessary actions on an ECR repository"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage"
        ],
        Resource = "${aws_ecr_repository.shop.arn}"
      },
      {
        Effect   = "Allow",
        Action   = "ecr:GetAuthorizationToken",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "ssm_policy" {
  name        = "SSMParameterAccessPolicy"
  description = "Allows access to AWS Systems Manager Parameter Store for ECS tasks"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:GetParametersByPath",
        ],
        Resource = "*",
      },
    ],
  })
}

resource "aws_s3_bucket_policy" "cloudfront_access_policy" {
  bucket = aws_s3_bucket.online_shop_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontServicePrincipalReadWrite"
      Effect    = "Allow"
      Principal = {
        Service = "cloudfront.amazonaws.com"
      }
      Action    = [
        "s3:GetObject",
        "s3:PutObject"
      ]
      Resource  = "${aws_s3_bucket.online_shop_bucket.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = "arn:aws:cloudfront::533267116580:distribution/E17Z0ZZ33VWQYV"
        }
      }
    }]
  })
}

