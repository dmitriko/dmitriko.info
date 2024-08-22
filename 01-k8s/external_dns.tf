
resource "aws_iam_role" "external_dns_role" {
  name = "external-dns-role-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer}"
        }
        Condition = {
          StringEquals = {
            "${data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer}:sub" = "system:serviceaccount:kube-system:external-dns"
          }
        }
      }
    ]
  })
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
        Resource = [
          "arn:aws:route53:::hostedzone/YOUR_HOSTED_ZONE_ID"
        ]
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
    name      = "external-dns"
    namespace = "kube-system"
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
    value = "upsert-only"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.external_dns_sa.metadata[0].name
  }
}
