module "network" {
  source = "../modules/network"
  vpc_cidr = "10.1.0.0/16"
  vpc_name = "staging-vpc"
}

module "eks_cluster" {
  source          = "../modules/eks_cluster"
  cluster_name    = "kris-staging"
  cluster_version = "1.27"
  subnet_ids      = module.network.private_subnet_ids
  security_group_id    = module.network.eks_security_group_id
  instance_types  = ["t3.medium"]
  desired_size    = 2
  min_size        = 1
  max_size        = 4
}
