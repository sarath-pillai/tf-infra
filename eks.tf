module "cluster" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.24.0"
  cluster_name    = "${var.environment}-cluster"
  cluster_version = var.cluster_version
  subnets = setunion(
    module.vpc.private_subnets,
    module.vpc.public_subnets,
  )
  vpc_id           = module.vpc.vpc_id
  enable_irsa      = false
  manage_aws_auth  = false
  default_platform = "linux"
  # write_kubeconfig cause permanent change detection by terraform
  # and is not a good method
  # See https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1012#issuecomment-695028105
  # for a better solution to get the kube config info
  write_kubeconfig               = false
  cluster_endpoint_public_access = true
  worker_ami_owner_id            = "296578399912"
  node_groups                    = var.clusters
}


####Additiaonl Services on top of eks######

resource "helm_release" "ingress-nginx" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.0.13"
  create_namespace = true
  depends_on = [
    module.cluster
  ]
}

resource "helm_release" "cert-manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  create_namespace = true

  set {
    name  = "version"
    value = "v1.4.0"
  }
  set {
    name  = "installCRDs"
    value = "true"
  }
  depends_on = [
    module.cluster,
    helm_release.ingress-nginx
  ]
}

resource "kubernetes_manifest" "clusterissuer_letsencrypt" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "letsencrypt"
    }
    "spec" = {
      "acme" = {
        "email" = "sarath@slashroot.in"
        "privateKeySecretRef" = {
          "name" = "letsencrypt"
        }
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "solvers" = [
          {
            "http01" = {
              "ingress" = {
                "class" = "nginx"
              }
            }
          },
        ]
      }
    }
  }
  depends_on = [
    module.cluster,
    helm_release.ingress-nginx,
    helm_release.cert-manager
  ]
}

data "kubernetes_service" "nginx" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
  depends_on = [
    helm_release.ingress-nginx
  ]
}
