resource "kubernetes_namespace" "webide" {
  metadata {
    name = "webide"
  }
}
resource "kubernetes_persistent_volume_claim" "home" {
  for_each = toset(local.user_names)
  metadata {
    name      = "home-${each.key}"
    namespace = kubernetes_namespace.webide.metadata.0.name
    annotations = {
      "volume.kubernetes.io/storage-provisioner" = "ebs.csi.aws.com"
    }
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
    storage_class_name = var.storage_class
  }
}
resource "kubernetes_service" "webide" {
  for_each = toset(local.user_names)
  metadata {
    name      = "webide-${each.key}"
    namespace = kubernetes_namespace.webide.metadata.0.name
  }

  spec {
    selector = {
      app = "webide-${each.key}"
    }

    port {
      port        = 8080
      target_port = 8080
    }
  }
}

resource "kubernetes_ingress_v1" "webide" {
  for_each = toset(local.user_names)
  metadata {
    name      = "webide-${each.key}"
    namespace = kubernetes_namespace.webide.metadata.0.name
    annotations = {
      "kubernetes.io/ingress.class"                = "alb"
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/certificate-arn"  = aws_acm_certificate.this.arn
      "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
      "alb.ingress.kubernetes.io/group.name"       = "${var.subdomain}-${var.domain}"
      "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/login"
    }
  }

  spec {
    ingress_class_name = "alb"
    rule {
      host = "${each.key}.${var.subdomain}.${var.domain}"
      http {
        path {
          backend {
            service {
              name = "webide-${each.key}"
              port {
                number = 8080
              }
            }
          }
          path      = "/*"
          path_type = "ImplementationSpecific"
        }
      }
    }
  }
}

resource "kubernetes_config_map" "this" {
  for_each = toset(local.user_names)
  metadata {
    name      = "setcontext-${each.key}"
    namespace = kubernetes_namespace.webide.metadata.0.name
  }

  data = {
    "setcontext.sh" = "aws eks update-kubeconfig --name ${var.cluster_name} && kubectl config set-context --current --namespace=${kubernetes_namespace.user_namespace[each.key].metadata[0].name}"
  }
}

resource "random_id" "token" {
  for_each    = toset(local.user_names)
  byte_length = 16
}

locals {
  webide_image = "${var.ecr_url}:latest"
}

resource "kubernetes_stateful_set_v1" "webide" {
  for_each = toset(local.user_names)
  metadata {
    name      = "webide-${each.key}"
    namespace = kubernetes_namespace.webide.metadata.0.name
    labels = {
      app = "webide-${each.key}"
    }
  }
  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "webide-${each.key}"
      }
    }
    service_name = "webide-${each.key}"
    template {
      metadata {
        labels = {
          app = "webide-${each.key}"
        }
      }
      spec {

        volume {
          name = "home"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.home[each.key].metadata[0].name
          }
        }
        volume {
          name = "entrypoint"
          config_map {
            name = kubernetes_config_map.this[each.key].metadata[0].name
          }
        }

        init_container {
          image   = local.webide_image
          name    = "chown"
          command = ["/bin/sh", "-c", "sudo chown 1000:1000 -R /home/coder && sh /opt/setcontext.sh"]
          env {
            name  = "AWS_DEFAULT_REGION"
            value = data.aws_region.current.name
          }
          env {
            name  = "AWS_ACCESS_KEY_ID"
            value = aws_iam_access_key.users[each.key].id
          }
          env {
            name  = "AWS_SECRET_ACCESS_KEY"
            value = aws_iam_access_key.users[each.key].secret
          }
          volume_mount {
            name       = "home"
            mount_path = "/home/coder"
          }
          volume_mount {
            name       = "entrypoint"
            mount_path = "/opt/setcontext.sh"
            sub_path   = "setcontext.sh"
          }
        }

        container {
          image             = local.webide_image
          name              = "main"
          image_pull_policy = "Always"

          resources {
            requests = {
              memory = "500Mi"
            }
            limits = {
              memory = "1Gi"
            }
          }
          env {
            name  = "AWS_DEFAULT_REGION"
            value = data.aws_region.current.name
          }
          env {
            name  = "AWS_ACCESS_KEY_ID"
            value = aws_iam_access_key.users[each.key].id
          }
          env {
            name  = "AWS_SECRET_ACCESS_KEY"
            value = aws_iam_access_key.users[each.key].secret
          }
          env {
            name  = "PASSWORD"
            value = random_id.token[each.key].hex
          }
          volume_mount {
            name       = "home"
            mount_path = "/home/coder"
          }
        }
      }
    }
  }
}

resource "local_file" "secrets" {
  for_each = toset(local.user_names)
  filename = "${path.module}/secrets/${each.key}.txt"
  content = templatefile(
    "${path.module}/student_secret.tpl",
    {
      user     = each.key
      domain   = "${var.subdomain}.${var.domain}"
      password = random_id.token[each.key].hex
    }
  )
}
