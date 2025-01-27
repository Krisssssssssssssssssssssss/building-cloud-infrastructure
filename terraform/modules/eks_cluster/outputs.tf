output "cluster_endpoint" {
  description = "EKS Cluster endpoint"
  value       = module.eks_cluster.cluster_endpoint
}

output "kubeconfig" {
  description = "Kubeconfig for the EKS cluster"
  value       = jsonencode({
    apiVersion = "v1"
    clusters = [
      {
        cluster = {
          server                   = module.eks_cluster.cluster_endpoint
          certificate-authority-data = module.eks_cluster.cluster_certificate_authority_data
        }
        name = module.eks_cluster.cluster_name
      }
    ]
    contexts = [
      {
        context = {
          cluster = module.eks_cluster.cluster_name
          user    = module.eks_cluster.cluster_name
        }
        name = module.eks_cluster.cluster_name
      }
    ]
    current-context = module.eks_cluster.cluster_name
    kind            = "Config"
    users = [
      {
        name = module.eks_cluster.cluster_name
        user = {
          token = module.eks_cluster.token
        }
      }
    ]
  })
}
