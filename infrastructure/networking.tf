terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "tf-backend-online-shop"
    key    = "state"
    region = "us-east-1"
  }
}

provider "aws" {
  region   = "us-east-1"
}

resource "aws_vpc" "online-shop" {
  cidr_block = "10.0.0.0/16"

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Shop = "vpc"
  }

}

resource "aws_internet_gateway" "online-shop" {
  vpc_id = aws_vpc.online-shop.id

  tags = {
    Shop = "igw"
  }
}

resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.online-shop.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = "true"
  tags = {
    Shop = "pbsubnet1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.online-shop.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Shop = "pbsubnet2"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.online-shop.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.online-shop.id
  }

  tags = {
    Shop = "rtable"
  }
}

resource "aws_route_table_association" "public_subnet1_association" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet2_association" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_subnet" "private_subnet1" {
  vpc_id            = aws_vpc.online-shop.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Shop = "pvsubnet1"
  }
}

resource "aws_subnet" "private_subnet2" {
  vpc_id            = aws_vpc.online-shop.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Shop = "pvsubnet2"
  }

}

resource "aws_security_group" "allow_tcp" {
  name        = "online-shop-backend"
  description = "Allow TCP inbound traffic on port 8080 and all outbound traffic"
  vpc_id      = aws_vpc.online-shop.id

  tags = {
    Name = "allow_tcp"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp_8080" {
  security_group_id = aws_security_group.allow_tcp.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tcp.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "online_shop_db" {
  name        = "online-shop-database"
  description = "Security group for online shop database"
  vpc_id      = aws_vpc.online-shop.id

  tags = {
    Name = "allow_tcp_5432"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp_5432" {
  security_group_id            = aws_security_group.online_shop_db.id
  referenced_security_group_id = aws_security_group.allow_tcp.id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp_5432_for_ecs_sg" {
  security_group_id            = aws_security_group.online_shop_db.id
  referenced_security_group_id = aws_security_group.ecs_task.id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_db" {
  security_group_id = aws_security_group.online_shop_db.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "online_shop_cache" {
  name        = "online-shop-cache"
  description = "Security group for online shop redis cache"
  vpc_id      = aws_vpc.online-shop.id

  tags = {
    Name = "allow_tcp_6379"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp_6379" {
  security_group_id            = aws_security_group.online_shop_cache.id
  referenced_security_group_id = aws_security_group.allow_tcp.id
  from_port                    = 6379
  ip_protocol                  = "tcp"
  to_port                      = 6379
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp_6379_for_ecs_sg" {
  security_group_id            = aws_security_group.online_shop_cache.id
  referenced_security_group_id = aws_security_group.ecs_task.id
  from_port                    = 6379
  ip_protocol                  = "tcp"
  to_port                      = 6379
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_ch" {
  security_group_id = aws_security_group.online_shop_cache.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "online_shop_alb" {
  name        = "online-shop-alb"
  description = "Security group for online shop alb"
  vpc_id      = aws_vpc.online-shop.id

  tags = {
    Name = "allow_tcp_8080_all"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp_80_all" {
  security_group_id = aws_security_group.online_shop_alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_alb" {
  security_group_id = aws_security_group.online_shop_alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_security_group" "ecs_task" {
  name        = "ecs-task"
  description = "Security group for ecs"
  vpc_id      = aws_vpc.online-shop.id

  tags = {
    Name = "ecs_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_from_inside_vpc" {
  security_group_id = aws_security_group.ecs_task.id
  cidr_ipv4         = aws_vpc.online-shop.cidr_block
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_ecs" {
  security_group_id = aws_security_group.ecs_task.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
