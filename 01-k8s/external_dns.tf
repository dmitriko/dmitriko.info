
locals {
    sa_name = "external-dns" // k8s service account named
    sa_ns   = "kube-system" // namespace where the service account is
}

resource "aws_iam_role" "external_dns_role" {
  name = "external-dns-role-${var.cluster_name}"

  assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role_policy.json
}

data "aws_iam_openid_connect_provider" "eks_openid_connect_provider" {
  url = data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer
}

data "aws_iam_policy_document" "external_dns_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.eks_openid_connect_provider.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${data.aws_iam_openid_connect_provider.eks_openid_connect_provider.url}:sub"
      values   = ["system:serviceaccount:${local.sa_ns}:${local.sa_name}"]
    }
  }
}

resource "aws_iam_policy" "external_dns_policy" {
  name = "ExternalDNSPolicy-${var.cluster_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "route53:GetChange"
        Resource = "arn:aws:route53:::change/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns_role_attachment" {
  role       = aws_iam_role.external_dns_role.name
  policy_arn = aws_iam_policy.external_dns_policy.arn
}

resource "kubernetes_service_account" "external_dns_sa" {
  metadata {
    name      = local.sa_name
    namespace = local.sa_ns
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns_role.arn
    }
  }
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "sources[0]"
    value = "ingress"
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "aws.zoneType"
    value = "public"
  }

  set {
    name  = "aws.region"
    value = data.aws_region.current.name
  }

  set {
    name  = "txtOwnerId"
    value = "external-dns"
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.external_dns_sa.metadata[0].name
  }
}
