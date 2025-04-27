
# this terraform file is automatically reconciled by the terraform controller. No need for pipelines that run terraform plan/apply
# Just write the terraform code and it will be applied automatically once merged to main




provider "aws" {
  region                      = "" # picked up from AWS_REGION env
  s3_force_path_style         = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
}

resource "aws_s3_bucket" "example" {
  bucket        = "example-tf-iac-bucket"
  force_destroy = true
}