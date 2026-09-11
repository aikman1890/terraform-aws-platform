# ==============================================================================
# terraform-aws-platform — root version constraints
# ==============================================================================
# terraform >= 1.5: enables `check` blocks, import blocks, and config-driven
#   move — all used by this repo.
# aws provider ~> 5.0: pinned to the v5 line; v6 introduced breaking changes
#   to several resource schemas this repo depends on.

terraform {
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
