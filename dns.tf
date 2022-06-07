resource "aws_route53_zone" "eks" {
  name = var.domain_name
}

resource "aws_route53_record" "www-dev" {
  zone_id = aws_route53_zone.eks.zone_id
  name    = "*"
  type    = "CNAME"
  ttl     = "300"
  records        = [data.kubernetes_service.nginx.external_ips[0]]
  depends_on = [
    helm_release.ingress-nginx    
  ]
}
