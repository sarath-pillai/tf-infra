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
  enable_irsa                    = false
  manage_aws_auth                = false
  default_platform               = "linux"
  # write_kubeconfig cause permanent change detection by terraform
  # and is not a good method
  # See https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1012#issuecomment-695028105
  # for a better solution to get the kube config info
  write_kubeconfig               = false
  cluster_endpoint_public_access = true
  worker_ami_owner_id            = "296578399912"
  node_groups                    = var.clusters
}

