terraform {
  required_version = "1.1.7"
  backend "s3" {
    bucket         = "tf-infra-state-rc-demo"
    key            = "terraform/state/tf-infra.tfstate"
    region         = "us-east-1"
  }
  required_providers {
    kubectl = {
      source = "gavinbunney/kubectl"
    }
    kubernetes = {
      version = "~> 2.7.0"
    }
    helm = {
      version = "1.3.1"
    }
  }
}

