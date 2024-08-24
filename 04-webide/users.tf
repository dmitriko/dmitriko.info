resource "aws_iam_user" "users" {
  for_each      = toset(local.user_names)
  name          = each.value
  path          = "/"
  force_destroy = true
}

resource "aws_iam_access_key" "users" {
  for_each = toset(local.user_names)
  user     = aws_iam_user.users[each.key].id
}


resource "aws_iam_policy" "user_access" {
  name        = "${var.tag}_users_access"
  path        = "/"
  description = "perms for users"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
       {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "eks:ListClusters"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_user_policy_attachment" "user_access" {
  for_each   = toset(local.user_names)
  user       = each.key
  policy_arn = aws_iam_policy.user_access.arn
  depends_on = [aws_iam_user.users]
}

resource "kubernetes_cluster_role_binding" "node_viewer_binding" {
  for_each = toset(local.user_names)

  metadata {
    name = "node-viewer-binding-${each.key}"
  }

  subject {
    kind      = "User"
    name      = each.key
    api_group = "rbac.authorization.k8s.io"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.node_viewer.metadata[0].name
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_cluster_role" "node_viewer" {
  metadata {
    name = "node-viewer"
  }

  rule {
    api_groups = ["", "storage.k8s.io", "cert-manager.io"]
    resources  = ["nodes", "storageclasses", "namespaces", "clusterissuers"]
    verbs      = ["get", "list", "watch"]
  }
}


resource "kubernetes_namespace" "user_namespace" {
  for_each = toset(local.user_names)
  metadata {
    name = each.key
  }
}

resource "kubernetes_role_v1" "access_default_ns" {

  metadata {
    name      = "eks-user-role" // not to be confused with IAM role
    namespace = "default"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding_v1" "access_default_ns" {
  for_each = toset(local.user_names)

  metadata {
    name      = "eks-users-role-binding-${each.key}"
    namespace = "default"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.access_default_ns.metadata[0].name

  }
  subject {
    kind      = "User"
    name      = each.key
    api_group = ""
  }
}

resource "kubernetes_role_v1" "access_own_ns" {
  for_each = toset(local.user_names)
  metadata {
    name      = each.key
    namespace = resource.kubernetes_namespace.user_namespace[each.key].metadata[0].name
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding_v1" "access_own_ns" {
  for_each = toset(local.user_names)

  metadata {
    name      = "user-role-binding"
    namespace = resource.kubernetes_namespace.user_namespace[each.key].metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = each.key
  }


  subject {
    kind      = "User"
    name      = each.key
    api_group = ""

  }
}
