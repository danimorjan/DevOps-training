resource "aws_s3_bucket" "terrafrom_backend" {
  bucket = "tf-backend-online-shop"

  tags = {
    Name        = "TF backend shop"
    Environment = "Test"
  }
}

resource "aws_s3_bucket" "online_shop_bucket" {
  bucket = "onlie-shop-frontend"
  tags = {
    Name        = "TF Frontend shop"
    Environment = "Test"
  }

}