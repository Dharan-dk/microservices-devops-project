module "vpc" {
  source = "./modules/vpc"

  project_name       = "cloudmart"
  environment        = "dev"
  enable_nat_gateway = true
}

module "eks" {
  source = "./modules/eks"

  cluster_name        = "cloudmart-eks-cluster"
  cluster_version     = "1.31"
  environment         = "dev"
  project_name        = "cloudmart"
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  node_group_name     = "cloudmart-node-group"
  node_instance_types = ["c7i-flex.large"]
  desired_size        = 2
  min_size            = 1
  max_size            = 4
  disk_size           = 50
  key_name            = "Root_EKS"
  allowed_ssh_cidrs   = ["13.205.252.20/32", "157.50.10.255/32"]

  tags = {
    Environment = "dev"
    Project     = "cloudmart"
    Owner       = "dharan"
  }
}
