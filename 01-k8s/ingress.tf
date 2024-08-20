resource "helm_release" "alb_ingress" {
  name       = "alb"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.6.2"
  namespace  = "kube-system"
  set {
    name  = "clusterName"
    value = var.cluster_name
  }
}
