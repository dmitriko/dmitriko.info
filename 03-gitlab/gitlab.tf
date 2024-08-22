data "aws_acm_certificate" "gitlab" {
  domain      = var.domain
  statuses    = ["ISSUED"]
  most_recent = true
}

resource "kubernetes_namespace" "gitlab" {
  metadata {
    name = "gitlab"
  }
}

resource "helm_release" "gitlab" {
  name       = "gitlab"
  namespace = kubernetes_namespace.gitlab.metadata[0].name
  repository = "https://charts.gitlab.io/"
  chart      = "gitlab"
  version    = "7.11.8" // 7.6.9 
  timeout    = 600
  wait       = true
  values = [templatefile("${path.module}/gitlab-values.tpl",
    {
      domain          = var.domain
      certificate_arn = data.aws_acm_certificate.gitlab.arn,
      group_name      = "gitlab"
      storage_class   = var.storage_class_name
    }
  )]
}

data "aws_lb" "gitlab" {
  depends_on = [helm_release.gitlab]
  tags = {
    "ingress.k8s.aws/stack" = "gitlab"
  }
}

data "aws_route53_zone" "this" {
  name = var.domain
}

//route53 records for subdomains
resource "aws_route53_record" "gitlab" {
  for_each = toset([ "kas", "minio", "registry", "gitlab" ])
  name     = "${each.value}.${var.domain}"
  type     = "CNAME"
  zone_id  = data.aws_route53_zone.this.zone_id
  records  = [data.aws_lb.gitlab.dns_name]
  ttl      = 300
}

data "kubernetes_secret" "gitlab_pwd" {
  metadata {
    name      = "gitlab-gitlab-initial-root-password"
    namespace = kubernetes_namespace.gitlab.metadata[0].name
  }
  depends_on = [helm_release.gitlab]
}
