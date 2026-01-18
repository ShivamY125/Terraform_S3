terraform {
  backend "s3" {
    bucket = "aws-terraform-state-17012026"
    key = "global/s3/terraform.tfstate"
    region = "ap-south-1"
  }
}