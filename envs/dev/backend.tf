# ==============================================================================
# dev backend — remote state in S3 with DynamoDB locking
# ==============================================================================
# IMPORTANT: backend blocks do not accept variables, so the bucket/table/key
# are hardcoded here. Create them once with a bootstrap run (or by hand):
#
#   aws s3api create-bucket --bucket mycompany-terraform-state --region us-east-1
#   aws s3api put-bucket-versioning --bucket mycompany-terraform-state \
#     --versioning-configuration Status=Enabled
#   aws dynamodb create-table --table-name mycompany-terraform-locks \
#     --attribute-definitions AttributeName=LockID,AttributeType=S \
#     --key-schema AttributeName=LockID,KeyType=HASH \
#     --billing-mode PAY_PER_REQUEST --region us-east-1

terraform {
  backend "s3" {
    bucket         = "REPLACE_ME-terraform-state"
    key            = "platform/dev/terraform.tfstate"
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
