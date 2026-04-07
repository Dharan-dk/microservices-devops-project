terraform {
  backend "s3" {
    bucket         = "cloudmart-terraform-state"
    key            = "cloudmart/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "cloudmart-terraform-lock"
    encrypt        = true
  }
}