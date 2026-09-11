# ==============================================================================
# EKS module — outputs
# ==============================================================================

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded cluster CA certificate."
  value       = aws_eks_cluster.this.certificate_authority[0].data
  sensitive   = true
}

output "cluster_version" {
  description = "Kubernetes version of the cluster."
  value       = aws_eks_cluster.this.version
}

output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for IRSA (empty when disabled)."
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.this[0].arn : ""
}

output "oidc_provider_url" {
  description = "Issuer URL of the OIDC provider (empty when disabled)."
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.this[0].url : ""
}

output "node_role_arn" {
  description = "ARN of the shared managed node group IAM role."
  value       = aws_iam_role.node.arn
}

output "cluster_security_group_id" {
  description = "Security group ID of the EKS control plane."
  value       = aws_security_group.cluster.id
}
