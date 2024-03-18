resource "aws_ecr_repository" "shop" {
  name = "shop"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_cloudwatch_log_group" "shop-group" {
  name = "shop-logs"

  tags = {
    Environment = "test"
  }
}

resource "aws_ecs_cluster" "shop" {
  name = "shop-cluster"

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.shop-group.name
      }
    }
  }

  tags = {
    Name        = "shop-cluster"
    Environment = "test"
  }
}

resource "aws_ecs_task_definition" "shop_task_definition" {
  family = "shop"
  container_definitions = jsonencode([
    {
      name        = "shop-container"
      image       = "${local.repo_url}:${var.image_tag}"
      cpu         = 512
      memory      = 768
      essential   = true,
      networkMode = "awsvpc"
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      environment = [
        {
          name  = "SPRING_DATASOURCE_URL"
          value = "${local.db_url}"
        },
        {
          name  = "SPRING_DATASOURCE_USERNAME"
          value = "postgres"
        },
        {
          name  = "SPRING_REDIS_HOST"
          value = "${local.redis_url}"
        },
        {
          name  = "SPRING_REDIS_PORT"
          value = "6379"
        }
      ],
      secrets = [
        {
          name      = "SPRING_DATASOURCE_PASSWORD"
          valueFrom = "arn:aws:ssm:us-east-1:533267116580:parameter/dbPassword"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "${aws_cloudwatch_log_group.shop-group.id}"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "shop-container"
        }
      }
    }
  ])
  network_mode       = "awsvpc"
  execution_role_arn = aws_iam_role.ecs_task_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn
}

resource "aws_ecs_service" "shop" {
  name                 = "shop"
  cluster              = aws_ecs_cluster.shop.id
  task_definition      = aws_ecs_task_definition.shop_task_definition.arn
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    subnets         = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
    security_groups = [aws_security_group.ecs_task.id]
  }
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    weight            = 100
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.shop_target_group_ecs.arn
    container_name   = "shop-container"
    container_port   = 8080
  }
}
