module "eks_cluster" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.33.1"
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  subnet_ids      = var.subnet_ids
}

module "eks_node_group" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "20.33.1"

  cluster_name   = var.cluster_name
  instance_types = var.instance_types
  subnet_ids     = var.private_subnet_ids
  min_size       = var.min_size
  max_size       = var.max_size
}
