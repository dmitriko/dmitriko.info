data "kubernetes_config_map_v1" "aws_auth" {
    metadata {
        name      = "aws-auth"
        namespace = "kube-system"
    }
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = data.kubernetes_config_map_v1.aws_auth.data.mapRoles
    mapUsers = templatefile("${path.module}/map-users.tpl",
      {
        "users"      = local.user_names,
        "admins"     = var.admins,
        "account_id" = data.aws_caller_identity.current.account_id
    })
  }
  force = true
  
  lifecycle {
    prevent_destroy = true
  }
}

