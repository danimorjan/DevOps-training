module "iam_github_oidc_provider" {
  source = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"

  tags = {
    Environment = "test"
  }
}

resource "aws_iam_role" "github_push_image_ecr_role" {
  name = "push-image-to-ecr-role-for-github"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = module.iam_github_oidc_provider.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringLike = {
          "${module.iam_github_oidc_provider.url}:sub" = "repo:danimorjan/DevOps-training:*"
        },
        StringEquals = {
          "${module.iam_github_oidc_provider.url}:aud" : "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Environment = "test"
  }
}


resource "aws_iam_role_policy_attachment" "ecr_access_attachment" {
  role       = aws_iam_role.github_push_image_ecr_role.name
  policy_arn = aws_iam_policy.ecr_allow_push_policy.arn
}

resource "aws_iam_role" "ec2_pull_ecr_role" {
  name = "ec2-push-to-ecr-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_pull_policy_attachment" {
  role       = aws_iam_role.ec2_pull_ecr_role.name
  policy_arn = aws_iam_policy.allow_ec2_pull.arn
}
