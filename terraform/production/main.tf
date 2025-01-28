module "network" {
  source   = "../modules/network"
  vpc_cidr = "10.2.0.0/16"
}

module "eks_cluster" {
  source          = "../modules/eks_cluster"
  cluster_name    = "kris-production"
  cluster_version = "1.27"
  subnet_ids      = module.network.private_subnet_ids
  instance_types  = ["t3.medium"]
  desired_size    = 2
  min_size        = 1
  max_size        = 4
}
