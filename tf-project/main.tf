
# this terraform file is automatically reconciled by the terraform controller. No need for pipelines that run terraform plan/apply
# Just write the terraform code and it will be applied automatically once merged to main



terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = false


  access_key = "test"
  secret_key = "test"
  region     = "us-east-1"

  endpoints {
    s3 = "http://docker.host.internal:4566"
  }
}

resource "aws_s3_bucket" "example" {
  bucket        = "example-tf-iac-bucket"
  force_destroy = true
}