# ==============================================================================
# EKS module — inputs
# ==============================================================================

variable "cluster_name" {
  description = "Name of the EKS cluster (also used as resource name prefix)."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "VPC ID the cluster and node groups live in."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the control plane ENIs and managed node groups."
  type        = list(string)
}

variable "endpoint_public_access" {
  description = "Allow public access to the Kubernetes API endpoint. Keep true for dev convenience; restrict via public_access_cidrs."
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_log_types" {
  description = "Control-plane log types shipped to CloudWatch Logs."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "enable_irsa" {
  description = "Create the IAM OIDC provider so service accounts can assume IAM roles."
  type        = bool
  default     = true
}

variable "enable_ebs_csi_driver" {
  description = "Install the aws-ebs-csi-driver addon with an IRSA-backed role."
  type        = bool
  default     = true
}

variable "ebs_csi_driver_version" {
  description = "Version of the aws-ebs-csi-driver addon."
  type        = string
  default     = "v1.32.0-eksbuild.1"
}

# --- system node group (cluster-critical addons) ---
variable "system_instance_types" {
  description = "Instance types for the system node group."
  type        = list(string)
  default     = ["t3.medium"]
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

# --- workload node group (application pods) ---
variable "workload_instance_types" {
  description = "Instance types for the workload node group."
  type        = list(string)
  default     = ["m5.large"]
}

variable "workload_capacity_type" {
  description = "ON_DEMAND or SPOT for the workload pool."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.workload_capacity_type)
    error_message = "workload_capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "workload_desired_size" {
  type    = number
  default = 3
}

variable "workload_min_size" {
  type    = number
  default = 2
}

variable "workload_max_size" {
  type    = number
  default = 10
}

variable "node_volume_size" {
  description = "Encrypted gp3 root volume size (GiB) for node launch templates."
  type        = number
  default     = 50
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default     = {}
}
