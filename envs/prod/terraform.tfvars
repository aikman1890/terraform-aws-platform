# prod environment values. Copy to your own file and adjust; never commit secrets.
project     = "platform"
environment = "prod"
aws_region  = "us-east-1"

vpc_cidr           = "10.20.0.0/16"
az_count           = 3
single_nat_gateway = false
enable_flow_logs   = true

kubernetes_version          = "1.30"
endpoint_public_access      = true
endpoint_public_access_cidrs = ["203.0.113.0/24"] # replace with your corporate egress IPs

system_instance_types = ["m5.large"]
system_desired_size   = 3
system_min_size       = 3
system_max_size       = 3

workload_instance_types = ["m5.large"]
workload_capacity_type  = "ON_DEMAND"
workload_desired_size   = 3
workload_min_size       = 3
workload_max_size       = 12

node_volume_size = 100
