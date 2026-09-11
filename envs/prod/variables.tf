# ==============================================================================
# prod environment — inputs (defaults tuned for HA)
# ==============================================================================

variable "project" {
  description = "Project name prefix."
  type        = string
  default     = "platform"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "VPC CIDR."
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "AZs to span."
  type        = number
  default     = 3
}

variable "single_nat_gateway" {
  description = "Prod uses one NAT gateway per AZ for zonal HA."
  type        = bool
  default     = false
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
  description = "Keep the public API endpoint on in prod only if you need it; restrict with endpoint_public_access_cidrs."
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "Office/VPN CIDRs allowed to reach the prod API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"] # lock this down to your corporate egress IPs before going live
}

variable "system_instance_types" {
  type    = list(string)
  default = ["m5.large"]
}

variable "system_desired_size" {
  type    = number
  default = 3
}

variable "system_min_size" {
  type    = number
  default = 3
}

variable "system_max_size" {
  type    = number
  default = 3
}

variable "workload_instance_types" {
  type    = list(string)
  default = ["m5.large"]
}

variable "workload_capacity_type" {
  description = "ON_DEMAND in prod for stability."
  type        = string
  default     = "ON_DEMAND"
}

variable "workload_desired_size" {
  type    = number
  default = 3
}

variable "workload_min_size" {
  type    = number
  default = 3
}

variable "workload_max_size" {
  type    = number
  default = 12
}

variable "node_volume_size" {
  type    = number
  default = 100
}
