terraform {
  backend "s3" {
    bucket  = "wordpress-app-state-26-10-2025"
    key     = "resume-website-backend/terraform.tfstate"
    region  = "eu-north-1"
    encrypt = true


  }
}
