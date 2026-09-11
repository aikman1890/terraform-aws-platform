# dev environment values. Copy to your own file and adjust; never commit secrets.
project     = "platform"
environment = "dev"
aws_region  = "us-east-1"

vpc_cidr           = "10.10.0.0/16"
az_count           = 3
single_nat_gateway = true
enable_flow_logs   = true

kubernetes_version     = "1.30"
endpoint_public_access = true

system_instance_types = ["t3.medium"]
system_desired_size   = 2
system_min_size       = 2
system_max_size       = 3

workload_instance_types = ["t3.medium"]
workload_capacity_type  = "SPOT"
workload_desired_size   = 2
workload_min_size       = 1
workload_max_size       = 6

node_volume_size = 50
