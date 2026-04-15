module "vpc" {
  source = "./modules/vpc"

  project_name       = "cloudmart"
  environment        = "dev"
  enable_nat_gateway = true
}

module "jenkins_agent" {
  source = "./modules/static-agent"

  key_name            = "Root_EKS"
  instance_type       = "c7i-flex.large"
  associate_public_ip = false
  vpc_id              = module.vpc.vpc_id
  subnet_id           = module.vpc.public_subnet_ids[0]
  allowed_ssh_cidrs   = ["13.205.252.20/32", "157.50.10.255/32"]

  # Custom AMI with pre-installed tools (set this to your custom AMI ID)
  use_custom_ami           = false
  custom_ami_id            = ""                           # Will use latest Ubuntu when use_custom_ami is false
  elastic_ip_allocation_id = "eipalloc-0dfcc84e92cc4f3f1" # Pre-allocated - 65.2.62.113

  tags = {
    Environment = "dev"
    Project     = "cloudmart"
    Owner       = "dharan"
  }
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
