resource "aws_db_instance" "online_shop_db" {
  identifier                  = "online-shop-db"
  allocated_storage           = 20
  engine                      = "postgres"
  engine_version              = "15.5"
  allow_major_version_upgrade = true
  instance_class              = var.rds_instance_type
  db_name                     = "postgres"
  username                    = "postgres"
  apply_immediately           = true
  password                    = "postgres"
  db_subnet_group_name        = aws_db_subnet_group.online_shop_subnet_group.name
  vpc_security_group_ids      = [aws_security_group.online_shop_db.id]
  multi_az                    = false

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "online-shop-db"
  }
}



resource "aws_db_subnet_group" "online_shop_subnet_group" {
  name       = "online-shop-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]

  tags = {
    Name = "online-shop-db-subnet-group"
  }
}

resource "aws_elasticache_cluster" "online_shop_cache" {
  cluster_id           = "online-shop-cache"
  engine               = "redis"
  node_type            = var.elasticache_instance_type
  num_cache_nodes      = 1
  subnet_group_name    = aws_elasticache_subnet_group.online_shop_subnet_group.name
  security_group_ids   = [aws_security_group.online_shop_cache.id]
  parameter_group_name = "default.redis7"

  tags = {
    Name = "online-shop-cache"
  }
}

resource "aws_elasticache_subnet_group" "online_shop_subnet_group" {
  name       = "online-shop-cache-subnet-group"
  subnet_ids = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]

  tags = {
    Name = "online-shop-cache-subnet-group"
  }
}


