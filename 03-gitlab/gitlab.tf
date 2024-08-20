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
  repository = "https://charts.gitlab.io/"
  chart      = "gitlab"
  namespace  = kubernetes_namespace.gitlab.metadata[0].name
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

data "aws_lb" "webide" {
  depends_on = [helm_release.gitlab]
  tags = {
    "ingress.k8s.aws/stack" = "gitlab"
  }
}

data "kubernetes_secret" "gitlab_pwd" {
  metadata {
    name      = "gitlab-gitlab-initial-root-password"
    namespace = kubernetes_namespace.gitlab.metadata[0].name
  }
  depends_on = [helm_release.gitlab]
}
