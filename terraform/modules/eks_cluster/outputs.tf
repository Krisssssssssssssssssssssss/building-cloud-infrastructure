output "cluster_endpoint" {
  description = "EKS Cluster API endpoint"
  value       = aws_eks_cluster.example.endpoint
}

output "cluster_certificate" {
  description = "Base64 encoded certificate data for the EKS cluster"
  value       = aws_eks_cluster.example.certificate_authority[0].data
}

# output "node_group_arn" {
#   description = "ARN of the EKS node group"
#   value       = aws_eks_node_group.node_group.arn
# }