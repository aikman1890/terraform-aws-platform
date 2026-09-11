# ==============================================================================
# Example: S3 bucket + IRSA-scoped IAM role
# ==============================================================================
# Standalone example showing the recommended pattern for giving a Kubernetes
# workload access to a private S3 bucket WITHOUT long-lived credentials:
#
#   1. An S3 bucket with versioning, SSE-S3 encryption, TLS-only access, and a
#      lifecycle rule that expires old versions and transitions to cheaper
#      storage classes.
#   2. An IAM role with a least-privilege policy scoped to that one bucket,
#      trustable by a Kubernetes ServiceAccount via IRSA
#      (see modules/eks outputs oidc_provider_arn/url).
#
# Usage:
#   cd examples/s3-iam
#   terraform init && terraform apply \
#     -var="name=app-data" \
#     -var="oidc_provider_arn=<from eks outputs>" \
#     -var="oidc_provider_url=<from eks outputs>"

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

variable "name" {
  description = "Base name for the bucket and role."
  type        = string
  default     = "app-data"
}

variable "environment" {
  description = "Environment tag."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider (modules/eks output oidc_provider_arn). Empty string skips the IRSA role."
  type        = string
  default     = ""
}

variable "oidc_provider_url" {
  description = "Issuer URL of the EKS OIDC provider (modules/eks output oidc_provider_url, https:// prefix stripped for the condition key)."
  type        = string
  default     = ""
}

variable "service_account_namespace" {
  description = "Kubernetes namespace of the ServiceAccount that may assume the role."
  type        = string
  default     = "default"
}

variable "service_account_name" {
  description = "Name of the Kubernetes ServiceAccount that may assume the role."
  type        = string
  default     = "app-sa"
}

variable "noncurrent_version_expiration_days" {
  description = "Delete noncurrent object versions after this many days."
  type        = number
  default     = 90
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      Example     = "s3-iam"
    }
  }
}

# Globally-unique bucket name without leaking the AWS account ID.
resource "random_pet" "suffix" {
  length    = 2
  separator = "-"
}

resource "aws_s3_bucket" "this" {
  bucket = "${var.name}-${random_pet.suffix.id}"

  tags = {
    Name = "${var.name}-bucket"
  }
}

# Block ALL public access — this bucket is private by design.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# SSE-S3 (aws/s3) server-side encryption on every object.
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Deny any request that doesn't use TLS.
resource "aws_s3_bucket_policy" "tls_only" {
  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.this.arn,
        "${aws_s3_bucket.this.arn}/*",
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.this]
}

# Lifecycle: keep current versions; transition old versions to cheaper tiers,
# then expire them. Also clean up incomplete multipart uploads after 7 days
# (the classic surprise line item on S3 bills).
resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "tier-and-expire-noncurrent"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ------------------------------------------------------------------------------
# IRSA role: least privilege, scoped to this bucket only
# ------------------------------------------------------------------------------
# The trust policy pins BOTH the exact service account (sub) and the audience,
# so no other pod in the cluster can assume this role.
resource "aws_iam_role" "app" {
  count = var.oidc_provider_arn != "" ? 1 : 0

  name = "${var.name}-app-irsa"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${var.oidc_provider_url}:sub" = "system:serviceaccount:${var.service_account_namespace}:${var.service_account_name}"
          "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = {
    Name = "${var.name}-app-irsa"
  }
}

resource "aws_iam_role_policy" "app_s3" {
  count = var.oidc_provider_arn != "" ? 1 : 0

  name = "${var.name}-app-s3-access"
  role = aws_iam_role.app[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListOwnBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
        ]
        Resource = aws_s3_bucket.this.arn
      },
      {
        Sid    = "ReadWriteOwnObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        # Scope to an app prefix rather than the whole bucket where possible.
        Resource = "${aws_s3_bucket.this.arn}/${var.service_account_namespace}/*"
      },
    ]
  })
}

output "bucket_name" {
  description = "Name of the created S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket."
  value       = aws_s3_bucket.this.arn
}

output "app_role_arn" {
  description = "ARN of the IRSA role for the application service account."
  value       = var.oidc_provider_arn != "" ? aws_iam_role.app[0].arn : null
}

output "service_account_annotation" {
  description = "Annotation to put on the Kubernetes ServiceAccount to bind it to the role."
  value       = var.oidc_provider_arn != "" ? { "eks.amazonaws.com/role-arn" = aws_iam_role.app[0].arn } : {}
}
