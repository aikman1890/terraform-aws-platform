# ==============================================================================
# dev environment — inputs (defaults tuned for cheap, not HA)
# ==============================================================================

variable "project" {
  description = "Project name prefix."
  type        = string
  default     = "platform"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR."
  type        = string
  default     = "10.10.0.0/16"
}

variable "az_count" {
  description = "AZs to span."
  type        = number
  default     = 3
}

variable "single_nat_gateway" {
  description = "Dev uses a single NAT gateway to save ~$90/mo."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Ship VPC flow logs to CloudWatch."
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.30"
}

variable "endpoint_public_access" {
  description = "Allow public API endpoint access in dev (lock down via security groups / VPN in prod)."
  type        = bool
  default     = true
}

variable "system_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "system_desired_size" {
  type    = number
  default = 2
}

variable "system_min_size" {
  type    = number
  default = 2
}

variable "system_max_size" {
  type    = number
  default = 3
}

variable "workload_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "workload_capacity_type" {
  description = "SPOT in dev for cost savings; ON_DEMAND in prod for stability."
  type        = string
  default     = "SPOT"
}

variable "workload_desired_size" {
  type    = number
  default = 2
}

variable "workload_min_size" {
  type    = number
  default = 1
}

variable "workload_max_size" {
  type    = number
  default = 6
}

variable "node_volume_size" {
  type    = number
  default = 50
}
