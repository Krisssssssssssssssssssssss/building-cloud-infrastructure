module "network" {
  source = "../modules/network"
  vpc_cidr = "10.1.0.0/16"
}

module "eks_cluster" {
  source           = "../modules/eks_cluster"
  cluster_name     = "kristijan-staging"
  cluster_version  = "1.27"
  subnet_ids       = concat(module.network.public_subnet_ids, module.network.private_subnet_ids)
  private_subnet_ids = module.network.private_subnet_ids
}
