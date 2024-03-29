
resource "aws_key_pair" "online_shop_instance_key" {
  key_name   = "online-shop-instance-key"
  public_key = ""

  lifecycle {
    prevent_destroy = true
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_iam_instance_profile" "ec2_pull_ecr_profile" {
  name = "ec2-pull-ecr-profile"
  role = aws_iam_role.ec2_pull_ecr_role.name
}

resource "aws_iam_instance_profile" "ec2_ecs_profile" {
  name = "ec2-ecs-profile"
  role = aws_iam_role.ec2_ecs_role.name
}

resource "aws_launch_template" "online_shop_launch_template" {
  name_prefix   = "online-shop-launch-template"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.ec2_instance_type
  user_data = base64encode(templatefile("dockeruserdata.tftpl", {
    db_endpoint    = local.db_url,
    cache_endpoint = local.redis_url,
    image_tag      = var.image_tag,
    repo_url       = local.repo_url
  }))
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_pull_ecr_profile.name
  }
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.allow_tcp.id]
}

data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_template" "online_shop_launch_template_ecs" {
  name_prefix   = "online-shop-launch-template"
  image_id      = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type = var.ec2_instance_type
  key_name      = var.ssh_key_name
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ecs_profile.name
  }
  vpc_security_group_ids = [aws_security_group.allow_tcp.id]

  user_data = base64encode(templatefile("ecsuserdata.tftpl", {}))
}

resource "aws_autoscaling_group" "online_shop_asg" {
  name = "online-shop-asg"
  launch_template {
    id      = aws_launch_template.online_shop_launch_template_ecs.id
    version = "$Latest"
  }
  vpc_zone_identifier = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
  min_size            = 1
  desired_capacity    = 1
  max_size            = 2
  health_check_type   = "ELB"
  #target_group_arns   = [aws_lb_target_group.shop_target_group.arn]
}

resource "aws_lb_target_group" "shop_target_group" {
  name     = "online-shop-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.online-shop.id

  health_check {
    path     = "/health"
    protocol = "HTTP"
    matcher  = "200"
  }
}

resource "aws_lb_target_group" "shop_target_group_ecs" {
  name        = "online-shop-target-group-ecs"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.online-shop.id

  health_check {
    path     = "/health"
    protocol = "HTTP"
    matcher  = "200"
  }
}

resource "aws_lb" "online_shop_lb" {
  name               = "online-shop-lb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
  security_groups    = [aws_security_group.online_shop_alb.id]

  enable_deletion_protection = false

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "online-shop-lb"
  }
}


resource "aws_lb_listener" "http_listener_ecs" {
  load_balancer_arn = aws_lb.online_shop_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.shop_target_group_ecs.arn
  }
}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = "shop-ecs-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.online_shop_asg.arn

    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}


resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.shop.name

  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
  }
}
