# ==============================================================================
# VPC module — inputs
# ==============================================================================

variable "name" {
  description = "Name prefix applied to all VPC resources."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Must be at least a /16 so the module can carve /20 public+private subnets per AZ."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) <= 16
    error_message = "vpc_cidr must be a valid CIDR of /16 or larger (e.g. 10.0.0.0/16)."
  }
}

variable "az_count" {
  description = "Number of availability zones to span (subnets, NATs, route tables scale with this)."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 6
    error_message = "az_count must be between 2 and 6."
  }
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway (dev/cost saving) instead of one per AZ (prod/HA)."
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Ship VPC flow logs to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "CloudWatch Logs retention for flow logs."
  type        = number
  default     = 90
}

variable "flow_logs_kms_key_id" {
  description = "Optional KMS key ARN for encrypting the flow-log log group. Defaults to CloudWatch-managed encryption."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
