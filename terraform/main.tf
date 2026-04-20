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

module "static_agent" {
  source = "./modules/static-agent"

  project_name      = "cloudmart"
  environment       = "dev"
  vpc_id            = module.vpc.vpc_id
  subnet_id         = module.vpc.public_subnet_ids[0] # Use first public subnet
  instance_type     = "c7i-flex.large"
  ami_id            = "ami-05d2d839d4f73aafb" # Ubuntu 24.04 LTS in ap-south-1
  root_volume_size  = 30
  key_name          = "Root_EKS"
  create_elastic_ip = true
  allowed_ssh_cidrs = ["0.0.0.0/0"] # Adjust for production

  tags = {
    Environment = "dev"
    Project     = "cloudmart"
    Owner       = "dharan"
    Purpose     = "CI/CD Static Agent"
  }

  depends_on = [module.vpc]
}
