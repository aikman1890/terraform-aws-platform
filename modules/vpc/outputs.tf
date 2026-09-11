# ==============================================================================
# VPC module — outputs
# ==============================================================================

output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the created VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (ordered by AZ)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (ordered by AZ)."
  value       = aws_subnet.private[*].id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways."
  value       = aws_nat_gateway.this[*].id
}

output "flow_log_group_name" {
  description = "CloudWatch log group receiving VPC flow logs (empty when disabled)."
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow_logs[0].name : ""
}
