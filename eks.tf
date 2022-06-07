module "cluster" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.24.0"
  cluster_name    = "${var.environment}-cluster"
  cluster_version = var.cluster_version
  subnets = setunion(
    module.vpc.private_subnets,
    module.vpc.public_subnets,
  )
  vpc_id                         = module.vpc.vpc_id
  map_roles                      = var.map_roles
  enable_irsa                    = false
  default_platform               = "linux"
  cluster_endpoint_public_access = true
  worker_ami_owner_id            = "296578399912"
  node_groups = var.clusters
}

