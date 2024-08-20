resource "helm_release" "ebs_csi_driver" {
  name       = "aws-ebs-csi-driver"
  namespace  = "kube-system"
  chart      = "aws-ebs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver/"
  version    = "2.25.0"
}

resource "kubernetes_storage_class" "ebs" {
  metadata {
    name = var.storage_class
  }

  storage_provisioner = "kubernetes.io/aws-ebs"

  parameters = {
    type = "gp2"
  }

  reclaim_policy = "Delete"

  allow_volume_expansion = true

  mount_options = ["debug"]

  volume_binding_mode = "Immediate"

  depends_on = [
    helm_release.ebs_csi_driver
  ]
}