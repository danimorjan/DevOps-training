resource "aws_s3_bucket" "terrafrom_backend" {
  bucket = "tf-backend-online-shop"

  tags = {
    Name        = "TF backend shop"
    Environment = "Test"
  }
}