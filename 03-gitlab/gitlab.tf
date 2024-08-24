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
  wait       = false
  values = [templatefile("${path.module}/gitlab-values.tpl",
    {
      domain          = var.domain
      certificate_arn = data.aws_acm_certificate.gitlab.arn,
      group_name      = "gitlab"
      storage_class   = var.storage_class_name
    }
  )]
}

data "kubernetes_secret" "gitlab_pwd" {
  metadata {
    name      = "gitlab-gitlab-initial-root-password"
    namespace = kubernetes_namespace.gitlab.metadata[0].name
  }
  depends_on = [helm_release.gitlab]
}
