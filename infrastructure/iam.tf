module "iam_github_oidc_provider" {
  source = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"

  tags = {
    Environment = "test"
  }
}

resource "aws_iam_role" "ci_cd_pipeline_role" {
  name = "ci-cd-pipeline"
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
  role       = aws_iam_role.ci_cd_pipeline_role.name
  policy_arn = local.admin_role
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

resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskrole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name        = "ecsTaskrole "
    Environment = "test"
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = local.task_exec_role
}

resource "aws_iam_role_policy_attachment" "ecs_task_ssm_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}

resource "aws_iam_role" "ec2_ecs_role" {
  name = "ec2-ecr-role"
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

resource "aws_iam_role_policy_attachment" "ec2_ecs_policy" {
  role       = aws_iam_role.ec2_ecs_role.name
  policy_arn = local.ec2_container_service_role_arn
}
