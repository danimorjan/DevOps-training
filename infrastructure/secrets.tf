resource "aws_ssm_parameter" "db_password" {
  name  = "dbPassword"
  type  = "String"
  value = "postgres"
}