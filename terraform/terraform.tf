provider "aws" {
}

terraform {
  backend "s3" {
    key                  = "emr-serverless-local-execution.tfstate"
    workspace_key_prefix = ""
    encrypt              = true
    region               = "eu-west-1"
    dynamodb_table       = "poc_terraform_backend"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60.0"
    }
  }
}
