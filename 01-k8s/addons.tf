resource "aws_eks_addon" "core-dns" {
  cluster_name = var.cluster_name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name = var.cluster_name
  addon_name   = "kube-proxy"
}

resource "helm_release" "cni" {
  name       = "cni"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-vpc-cni"
  namespace  = "kube-system"
  version    = "1.18.3"
}