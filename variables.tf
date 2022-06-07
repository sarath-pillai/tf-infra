variable "environment" {
  description = "Target environment where the resources will be deployed"
  default = "demo"
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "cluster_version" {
  type    = string
  default = "1.21"
}

variable "clusters" {
  default = {
    web = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1

      instance_types = ["t3.large"]
      k8s_labels = {
      workload-web-low = "accept",
      workload-web-medium = "accept",
      workload-web-critical = "accept"
      }
      additional_tags = {
        WorkLoadType = "web"
      }
    }
 }
}

