
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

resource "aws_launch_template" "online_shop_launch_template" {
  name_prefix   = "online-shop-launch-template"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.ec2_instance_type
  user_data = base64encode(templatefile("userdata.tftpl", {
    db_endpoint    = local.db_url,
    cache_endpoint = aws_elasticache_cluster.online_shop_cache.cache_nodes[0].address,
    jar_url        = local.jar_url
  }))
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.allow_tcp.id]
}

resource "aws_autoscaling_group" "online_shop_asg" {
  name = "online-shop-asg"
  launch_template {
    id      = aws_launch_template.online_shop_launch_template.id
    version = "$Latest"
  }
  vpc_zone_identifier = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
  min_size            = 0
  desired_capacity    = 0
  max_size            = 0
  health_check_type   = "ELB"
  target_group_arns   = [aws_lb_target_group.shop_target_group.arn]
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

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.online_shop_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.shop_target_group.arn
  }
}
