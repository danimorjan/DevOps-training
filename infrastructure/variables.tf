variable "ssh_key_name" {
  description = "Name of the SSH key pair"
  default     = "online-shop-instance-key"
}

variable "ec2_instance_type" {
  description = "Instance type for EC2 instances"
  default     = "t2.micro"
}

variable "rds_instance_type" {
  description = "Instance type for RDS"
  default     = "db.t3.micro"
}

variable "image_tag" {
  description = "Docker image tag"
  default     = "bad940b1ec09bcce65fe3af2e43818f952d432cb"
}

variable "elasticache_instance_type" {
  description = "Instance type for ElastiCache"
  default     = "cache.t3.micro"
}

variable "app_version" {
  description = "URL of the JAR file to download"
  type        = string
  default     = "v0.0.1"
}

locals {
  db_url                         = "jdbc:postgresql://${aws_db_instance.online_shop_db.endpoint}/postgres"
  repo_url                       = aws_ecr_repository.shop.repository_url
  redis_url                      = aws_elasticache_cluster.online_shop_cache.cache_nodes[0].address
  ec2_container_service_role_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  task_exec_role                 = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  admin_role                     = "arn:aws:iam::aws:policy/AdministratorAccess"
  jar_url                        = "https://github.com/msg-CareerPaths/aws-devops-demo-app/releases/download/${var.app_version}/online-shop-${var.app_version}.jar"
}

output "database_endpoint" {
  value = aws_db_instance.online_shop_db.endpoint
}

output "cache_endpoint" {
  value = aws_elasticache_cluster.online_shop_cache.cache_nodes[0].address
}

output "ssm_dbpassword_arn" {
  value = aws_ssm_parameter.db_password.arn
}

# output "application_base_url" {
#   value = "http://${aws_lb.online_shop_lb.dns_name}"
# }
