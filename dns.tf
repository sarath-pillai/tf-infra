# The below subdomain will only be used by the applications deployed on EKS to auto register using external-dns https://github.com/kubernetes-sigs/external-dns
# The NS record for the below subdomain has to be manually added to the root zone ofcourse.

resource "aws_route53_zone" "eks" {
  name = "demo.slashroot.in"
}
