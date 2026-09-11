# ==============================================================================
# prod environment — wires the vpc + eks modules together
# ==============================================================================
# Prod runs the same modules as dev with HA knobs turned on: one NAT gateway
# per AZ, on-demand m5.large workers, tighter node counts, and a restricted
# API endpoint.

locals {
  name = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name               = local.name
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  single_nat_gateway = var.single_nat_gateway
  enable_flow_logs   = var.enable_flow_logs

  tags = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name                = local.name
  kubernetes_version          = var.kubernetes_version
  vpc_id                      = module.vpc.vpc_id
  private_subnet_ids          = module.vpc.private_subnet_ids
  endpoint_public_access      = var.endpoint_public_access
  endpoint_public_access_cidrs = var.endpoint_public_access_cidrs

  system_instance_types = var.system_instance_types
  system_desired_size   = var.system_desired_size
  system_min_size       = var.system_min_size
  system_max_size       = var.system_max_size

  workload_instance_types = var.workload_instance_types
  workload_capacity_type  = var.workload_capacity_type
  workload_desired_size   = var.workload_desired_size
  workload_min_size       = var.workload_min_size
  workload_max_size       = var.workload_max_size

  node_volume_size = var.node_volume_size

  tags = local.common_tags
}
