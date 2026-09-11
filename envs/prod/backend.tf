# ==============================================================================
# prod backend — remote state in S3 with DynamoDB locking
# ==============================================================================
# IMPORTANT: backend blocks do not accept variables, so the bucket/table/key
# are hardcoded here. Use a DIFFERENT state key per environment so dev and
# prod can never collide. See envs/dev/backend.tf for the one-time bootstrap
# commands to create the state bucket and lock table.

terraform {
  backend "s3" {
    bucket         = "REPLACE_ME-terraform-state"
    key            = "platform/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "REPLACE_ME-terraform-locks"
    encrypt        = true
  }

  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
