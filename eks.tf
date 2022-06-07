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

resource "aws_iam_policy" "external_dns_iam_policy" {
  name        = "${var.environment}-external-dns-iam-policy"
  path        = "/"
  description = "external dns policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "kubernetes_service_account" "serviceaccount-external_dns" {
  automount_service_account_token = true
  metadata {
    name        = "serviceaccount-external-dns"
    annotations = { "eks.amazonaws.com/role-arn" : module.assume_role_external_dns.this_iam_role_arn }
    namespace   = "kube-system"
  }
}

module "assume_role_external_dns" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.6.0"
  create_role                   = true
  role_name                     = "${var.environment}-external-dns-iam-role"
  provider_url                  = replace(module.cluster.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.external_dns_iam_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:serviceaccount-external-dns"]
  depends_on = [
    module.cluster,
  ]
}

resource "helm_release" "helm_release_external-dns" {
  name       = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  version    = "6.5.3"
  namespace  = "kube-system"
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = "serviceaccount-external-dns"
  }
  set {
    name  = "policy"
    value = "upsert-only"
  }
  depends_on = [
    module.cluster,
    module.assume_role_external_dns,
    kubernetes_service_account.serviceaccount-external_dns
  ]
}


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
    helm_release.cert-manager,
    helm_release.helm_release_external-dns
  ]
}


