resource "aws_route53_zone" "eks" {
  name = var.domain_name
}

resource "aws_route53_record" "wildcard" {
  zone_id = aws_route53_zone.eks.zone_id
  name    = "*"
  type    = "CNAME"
  ttl     = "300"
  records = [data.kubernetes_service.nginx.status.0.load_balancer.0.ingress.0.hostname]
  depends_on = [
    helm_release.ingress-nginx
  ]
}
